(function() {
    'use strict';
    // deferredSetup.js must be loaded first

    var drawScene = function(state) {
        for (var i = 0; i < state.models.length; i++) {
            var m = state.models[i];

            // If you want to render one model many times, note:
            // readyModelForDraw only needs to be called once.
            readyModelForDraw(R.progCopy, m);

            drawReadyModel(m);
        }
    };

    var bindTexturesForLightPass = function(prog) {
        gl.useProgram(prog.prog);

        // * Bind all of the g-buffers and depth buffer as texture uniform
        //   inputs to the shader
        for (var i = 0; i < R.NUM_GBUFFERS; i++) {
            gl.activeTexture(gl['TEXTURE' + i]);
            gl.bindTexture(gl.TEXTURE_2D, R.pass_copy.gbufs[i]);
            gl.uniform1i(prog.u_gbufs[i], i);
        }
        gl.activeTexture(gl['TEXTURE' + R.NUM_GBUFFERS]);
        gl.bindTexture(gl.TEXTURE_2D, R.pass_copy.depthTex);
        gl.uniform1i(prog.u_depth, R.NUM_GBUFFERS);
    };

    var bindTexturePR = function(prog, tex, data, textureID, size) {
        gl.activeTexture(gl['TEXTURE' + textureID]);
        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, size, 1, 0, gl.RGBA, gl.FLOAT, data);

        gl.uniform1i(prog.u_lightsPR, textureID);
    };

    var bindTextureRGB = function(prog, uniformTarget, tex, data, textureID, size) {
        gl.activeTexture(gl['TEXTURE' + textureID]);
        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, size, 1, 0, gl.RGB, gl.FLOAT, data);

        gl.uniform1i(uniformTarget, textureID);
    };

    var bindTextureLum = function(prog, uniformTarget, tex, data, textureID, xsize, ysize) {
        gl.activeTexture(gl['TEXTURE' + textureID]);
        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.LUMINANCE, xsize, ysize, 0, gl.LUMINANCE, gl.FLOAT, data);

        gl.uniform1i(uniformTarget, textureID);
    };

    R.deferredRender = function(state) {
        if (!aborted && (
            !R.progCopy ||
            !R.progRed ||
            !R.progClear ||
            !R.prog_Ambient ||
            !R.prog_BlinnPhong_PointLight ||
            !R.progScissor ||
            !R.progTiled ||
            !R.prog_Debug || !R.progPost1)) {
            console.log('waiting for programs to load...');
            return;
        }

        // Move the R.lights
        for (var i = 0; i < R.lights.length; i++) {
            var mn = R.light_min[1];
            var mx = R.light_max[1];
            //R.lights[i].pos[1] = (R.lights[i].pos[1] + R.light_dt - mn + mx) % mx + mn;
        }

        // Update light textures with new position values
        R.writeLightTextures();

        // Execute deferred shading pipeline
        R.pass_copy.render(state);

        if (cfg && cfg.debugView >= 0) {
            // Do a debug render instead of a regular render
            // Don't do any post-processing in debug mode
            R.pass_debug.render(state);
        } else if (cfg.optimization == 1) {
            R.pass_tiled.render(state);
            R.pass_post1.render(state);
        } else {
            // both unoptimized deferred and scissor pass through here
            R.pass_deferred.render(state);
            R.pass_post1.render(state);
        }
    };

    /**
     * 'copy' pass: Render into g-buffers
     */
    R.pass_copy.render = function(state) {
        // * Bind the framebuffer R.pass_copy.fbo
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_copy.fbo);

        // * Clear screen using R.progClear
        renderFullScreenQuad(R.progClear);
        // * Clear depth buffer to value 1.0 using gl.clearDepth and gl.clear
        gl.clearDepth(1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        // * "Use" the program R.progCopy.prog
        gl.useProgram(R.progCopy.prog);

        var m = state.cameraMat.elements;
        // * Upload the camera matrix m to the uniform R.progCopy.u_cameraMat
        //   using gl.uniformMatrix4fv
        gl.uniformMatrix4fv(R.progCopy.u_cameraMat, false, m);

        // * Draw the scene
        drawScene(state);
    };

    R.pass_debug.render = function(state) {
        // * Unbind any framebuffer, so we can write to the screen
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);

        // * Bind/setup the debug "lighting" pass
        // * Tell shader which debug view to use
        bindTexturesForLightPass(R.prog_Debug);
        gl.uniform1i(R.prog_Debug.u_debug, cfg.debugView);

        // * Render a fullscreen quad to perform shading on
        renderFullScreenQuad(R.prog_Debug);
    };

    /**
     * 'tiled' pass: Add lighting results for each individual light
     */
    R.pass_tiled.render = function(state) {
        // * Bind R.pass_deferred.fbo to write into for later postprocessing
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_deferred.fbo);

        // * Clear depth to 1.0 and color to black
        gl.clearColor(0.0, 0.0, 0.0, 0.0);
        gl.clearDepth(1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        // * Bind/setup the ambient pass, and render using fullscreen quad
        bindTexturesForLightPass(R.prog_Ambient);
        gl.uniform1f(R.prog_Ambient.u_ambientTerm, cfg.ambient);
        renderFullScreenQuad(R.prog_Ambient);

        // Constants
        var TILE_SIZE = cfg.tileSize;
        var TILES_WIDTH  = Math.ceil((width+1)  / TILE_SIZE);
        var TILES_HEIGHT = Math.ceil((height+1) / TILE_SIZE);
        var NUM_TILES = TILES_WIDTH * TILES_HEIGHT;

        // [ tiles ] [ lights per tile ].
        var tileLights = [];

        // Create an inner array for each outer array.
        for (var i = 0; i < TILES_WIDTH * TILES_HEIGHT; i++) {
            tileLights.push([]);
        }

        // Store lights into tileLights.
        for (var lightIdx = 0; lightIdx < R.lights.length; lightIdx++) {
            var light = R.lights[lightIdx];
            var lightIdxStore = (lightIdx + 0.5) / R.lights.length;
            var sc = getScissorForLight(state.viewMat, state.projMat, light);
            // xmin, ymin, xwidth, ywidth
            if (sc !== null && sc[2] > 0 && sc[3] > 0) {
                var tileX = Math.floor(sc[0] / TILE_SIZE);
                var tileY = Math.floor(sc[1] / TILE_SIZE);
                var tileW = Math.ceil (sc[2] / TILE_SIZE)+1;
                var tileH = Math.ceil (sc[3] / TILE_SIZE)+1;

                for (var y = tileY; y < tileY + tileH; y++) {
                    for (var x = tileX; x < tileX + tileW; x++) {
                        var idx = x + (TILES_HEIGHT - 1 - y) * TILES_WIDTH;
                        if (idx >= 0 && idx < TILES_WIDTH * TILES_HEIGHT) {
                            tileLights[idx].push(lightIdxStore);
                        }
                    }
                }
            } else {
                continue;
            }
        }

        // Generate textures from tileLights.
        var lightIndices = new Float32Array(R.MAX_LIGHTS * NUM_TILES);
        var tileOffsets  = new Float32Array(3 * NUM_TILES);

        // Loop over tiles
        var totalOffset = 0;
        for (var tileIdx = 0; tileIdx < TILES_WIDTH * TILES_HEIGHT; tileIdx++) {
            var lights = tileLights[tileIdx];
            var len = lights.length;

            tileOffsets[3*tileIdx] = len + 0.5;
            tileOffsets[3*tileIdx+1] = (totalOffset % 4096) + 0.5;
            tileOffsets[3*tileIdx+2] = Math.floor(totalOffset / 4096) + 0.5;

            for (lightIdx = 0; lightIdx < Math.min(len, R.MAX_LIGHTS); lightIdx++) {
                lightIndices[totalOffset] = lights[lightIdx];
                totalOffset++;
            }
        }

        // Enable blending and scissor testing
        gl.enable(gl.BLEND);
        gl.blendFunc(gl.ONE, gl.ONE);
        gl.enable(gl.SCISSOR_TEST);

        // Bind/setup the tiled program and uniforms that don't change.
        var program = R.progTiled;
        bindTexturesForLightPass(program);

        var cam = state.cameraPos;
        gl.uniform3f(program.u_cameraPos, cam.x, cam.y, cam.z);
        gl.uniform1i(program.u_toon, cfg.toon ? 1 : 0);

        bindTexturePR(program,
                      R.pass_tiled.lightDataPosRad, R.lightTexturePosRad,
                      R.NUM_GBUFFERS+1, R.lights.length);

        bindTextureRGB(program, program.u_lightsC,
                       R.pass_tiled.lightDataCol, R.lightTextureCol,
                       R.NUM_GBUFFERS+2, R.lights.length);

        var xsize = 4096;
        var ysize = Math.ceil(totalOffset / 4096);

        bindTextureLum(program, program.u_lightIndices,
                       R.pass_tiled.lightTileTex, lightIndices,
                       R.NUM_GBUFFERS+3, xsize, ysize);

        gl.uniform2f(program.u_lightStep, 1 / xsize, 1 / ysize);
        gl.uniform1i(program.u_debugView, cfg.tileDebugView);

        bindTextureRGB(program, program.u_tileOffsets,
                       R.pass_tiled.tileOffsetTex, tileOffsets,
                       R.NUM_GBUFFERS+4, tileOffsets.length / 3);

        // Loop through the tiles and call the program for each.
        for (var x = 0; x < TILES_WIDTH; x++) {
            for (var y = 0; y < TILES_HEIGHT; y++) {
                gl.scissor(x * TILE_SIZE, y * TILE_SIZE, TILE_SIZE, TILE_SIZE);
                var idx = x + (TILES_HEIGHT - 1 - y) * TILES_WIDTH;
                gl.uniform1f(program.u_tileIdx, (idx + 0.5) / NUM_TILES);
                renderFullScreenQuad(program);
            }
        }

        // Disable gl features
        gl.disable(gl.SCISSOR_TEST);
        gl.disable(gl.BLEND);
    };

    /**
     * 'deferred' pass: Add lighting results for each individual light
     */
    R.pass_deferred.render = function(state) {
        // * Bind R.pass_deferred.fbo to write into for later postprocessing
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_deferred.fbo);

        // * Clear depth to 1.0 and color to black
        gl.clearColor(0.0, 0.0, 0.0, 0.0);
        gl.clearDepth(1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        // * _ADD_ together the result of each lighting pass

        // Enable blending and use gl.blendFunc to blend with:
        //   color = 1 * src_color + 1 * dst_color
        gl.enable(gl.BLEND);
        gl.blendFunc(gl.ONE, gl.ONE);

        // * Bind/setup the ambient pass, and render using fullscreen quad
        bindTexturesForLightPass(R.prog_Ambient);
        gl.uniform1f(R.prog_Ambient.u_ambientTerm, cfg.ambient);
        renderFullScreenQuad(R.prog_Ambient);

        if (cfg.optimization == 0) {
            gl.enable(gl.SCISSOR_TEST);
        } else {
        }

        // * Bind/setup the Blinn-Phong pass, and render using fullscreen quad
        var cam = state.cameraPos;
        var program = cfg.debugScissor ? R.progScissor : R.prog_BlinnPhong_PointLight;
        bindTexturesForLightPass(program);
        gl.uniform1i(program.u_toon, cfg.toon ? 1 : 0);
        for (var i = 0; i < R.lights.length; i++) {
            var light = R.lights[i];
            var sc = getScissorForLight(state.viewMat, state.projMat, light);
            if (sc !== null && sc[2] > 0 && sc[3] > 0) {
                gl.scissor(sc[0], sc[1], sc[2], sc[3]);
            } else {
                continue;
            }

            if (cfg.debugScissor) {
                gl.uniform3f(program.u_lightCol,
                            light.col[0], light.col[1], light.col[2]);
            } else {
                gl.uniform3f(program.u_cameraPos,
                            cam.x, cam.y, cam.z);
                gl.uniform3f(program.u_lightCol,
                            light.col[0], light.col[1], light.col[2]);
                gl.uniform3f(program.u_lightPos,
                            light.pos[0], light.pos[1], light.pos[2]);
                gl.uniform1f(program.u_lightRad, cfg.lightRadius);
            }
            renderFullScreenQuad(program);
        }
        gl.disable(gl.SCISSOR_TEST);

        // Disable blending so that it doesn't affect other code
        gl.disable(gl.BLEND);
    };

    /**
     * 'post1' pass: Perform (first) pass of post-processing
     */
    R.pass_post1.render = function(state) {
        // * Unbind any existing framebuffer (if there are no more passes)
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);

        // * Clear the framebuffer depth to 1.0
        gl.clearDepth(1.0);
        gl.clear(gl.DEPTH_BUFFER_BIT);

        // * Bind the postprocessing shader program
        gl.useProgram(R.progPost1.prog);

        // * Bind the deferred pass's color output as a texture input
        // Set gl.TEXTURE0 as the gl.activeTexture unit
        gl.activeTexture(gl.TEXTURE0);
        // Bind the TEXTURE_2D, R.pass_deferred.colorTex to the active texture unit
        gl.bindTexture(gl.TEXTURE_2D, R.pass_deferred.colorTex);
        // Configure the R.progPost1.u_color uniform to point at texture unit 0
        gl.uniform1i(R.progPost1.u_color, 0);

        // * Render a fullscreen quad to perform shading on
        renderFullScreenQuad(R.progPost1);
    };

    var renderFullScreenQuad = (function() {
        // The variables in this function are private to the implementation of
        // renderFullScreenQuad. They work like static local variables in C++.

        // Create an array of floats, where each set of 3 is a vertex position.
        // You can render in normalized device coordinates (NDC) so that the
        // vertex shader doesn't have to do any transformation; draw two
        // triangles which cover the screen over x = -1..1 and y = -1..1.
        // This array is set up to use gl.drawArrays with gl.TRIANGLE_STRIP.
        var positions = R.quadPositions;

        var vbo = null;

        var init = function() {
            // Create a new buffer with gl.createBuffer, and save it as vbo.
            vbo = gl.createBuffer();

            // Bind the VBO as the gl.ARRAY_BUFFER
            gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
            // Upload the positions array to the currently-bound array buffer
            // using gl.bufferData in static draw mode.
            gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);
        };

        return function(prog) {
            if (!vbo) {
                // If the vbo hasn't been initialized, initialize it.
                init();
            }

            // Bind the program to use to draw the quad
            gl.useProgram(prog.prog);

            // Bind the VBO as the gl.ARRAY_BUFFER
            gl.bindBuffer(gl.ARRAY_BUFFER, vbo);

            // Enable the bound buffer as the vertex attrib array for
            // prog.a_position, using gl.enableVertexAttribArray
            gl.enableVertexAttribArray(vbo);

            // Use gl.vertexAttribPointer to tell WebGL the type/layout for
            // prog.a_position's access pattern.
            gl.vertexAttribPointer(vbo, 3, gl.FLOAT, false, 0, 0);

            // Use gl.drawArrays (or gl.drawElements) to draw your quad.
            gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

            // Unbind the array buffer.
            gl.bindBuffer(gl.ARRAY_BUFFER, null);
        };
    })();
})();
