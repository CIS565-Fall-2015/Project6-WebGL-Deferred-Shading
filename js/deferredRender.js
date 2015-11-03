(function() {
    'use strict';
    // deferredSetup.js must be loaded first

    var TILE_SIZE = 32;
    var MAX_LIGHTS_PER_TILE =  TILE_SIZE * TILE_SIZE / 2;
    var NUM_TILES_WIDE;
    var NUM_TILES_TALL;
    var NUM_TILES;

    R.deferredRender = function(state) {
        if (!aborted && (
            !R.progCopy ||
            !R.progRed ||
            !R.progClear ||
            !R.prog_Ambient ||
            !R.prog_BlinnPhong_PointLight ||
            !R.prog_Toon ||
            !R.prog_ToonAmbient ||
            !R.prog_Debug ||
            !R.progPost1 ||
            !R.progCopyCompressed ||
            !R.prog_DebugCompressed ||
            !R.progClearCompressed ||
            !R.prog_BlinnPhong_PointLightCompressed ||
            !R.prog_AmbientCompressed ||
            !R.prog_DebugTiling ||
            !R.prog_BlinnPhongTiling)) {
            console.log('waiting for programs to load...');
            return;
        }

        // Move the R.lights
        for (var i = 0; i < R.lights.length; i++) {
            // OPTIONAL TODO: Edit if you want to change how lights move
            var mn = R.light_min[1];
            var mx = R.light_max[1];
            R.lights[i].pos[1] = (R.lights[i].pos[1] + R.light_dt - mn + mx) % mx + mn;
        }

        // Execute deferred shading pipeline

        // CHECKITOUT: START HERE! You can even uncomment this:
        //debugger;
        /*
        { // TODO: this block should be removed after testing renderFullScreenQuad
            gl.bindFramebuffer(gl.FRAMEBUFFER, null);
            // TODO: Implement/test renderFullScreenQuad first
            renderFullScreenQuad(R.progRed);
            return;
        } */

        // copy pass
if (cfg.enableTiling || cfg.debugTiling) {
            R.pass_copy_tile.render(state);
        } else if (cfg.compressedGbuffers) {
            R.pass_copy_compressed.render(state);
        } else {
            R.pass_copy.render(state);
        }

        // deferred and post process passes
        if (cfg.debugTiling) {
            R.pass_debug_tile.render(state);
        }
        else if (cfg.enableTiling) {
            R.pass_deferred_tile.render(state);
            R.pass_post1.render(state, R.pass_deferred_tile.colorTex);            
        }
        else if (cfg.compressedGbuffers && cfg.debugView >= 0) {
            R.pass_debug_compressed.render(state);
        }
        else if (cfg.compressedGbuffers) {
            R.pass_deferred_compressed.render(state);
            R.pass_post1.render(state, R.pass_deferred_compressed.colorTex);
        }
        else if (cfg && cfg.debugScissor) {
            // do a scissor debug render instead of a regular render.
            // don't do any post-proccessing in debug mode.
            R.pass_debug.debugScissor(state);
        }
        else if (cfg && cfg.debugView >= 0) {
            // Do a debug render instead of a regular render
            // Don't do any post-processing in debug mode
            R.pass_debug.render(state);
        }
        else if (cfg && cfg.enableToon){
            R.pass_toon.render(state);
            R.pass_post1.render(state, R.pass_deferred.colorTex);
        }
        else {
            // * Deferred pass and postprocessing pass(es)
            // TODO: uncomment these
            R.pass_deferred.render(state);
            R.pass_post1.render(state, R.pass_deferred.colorTex);

            // OPTIONAL TODO: call more postprocessing passes, if any
        }
    };

    R.bounded = function(point, min, max) {
        var boundedX = (min[0] <= point[0]) && (point[0] <= max[0]);
        var boundedY = (min[1] <= point[1]) && (point[1] <= max[1]);
        return boundedX && boundedY;
    }

    // takes boxes like what getScissorForLight returns and returns if
    // they overlap or not.
    R.boxOverlap = function(box1, box2) {
        // the boxes are given as bottom left x, y, width, height
        // check each corner of box1 against box2
        var minX = box2[0];
        var minY = box2[1];        
        var maxX = box2[0] + box2[2];
        var maxY = box2[1] + box2[3];
        if (R.bounded([box1[0], box1[1]], [minX, minY], [maxX, maxY])) {
            return true;
        }
        if (R.bounded([box1[0] + box1[2], box1[1]], [minX, minY], [maxX, maxY])) {
            return true;
        }
        if (R.bounded([box1[0] + box1[2], box1[1] + box1[3]], [minX, minY], [maxX, maxY])) {
            return true;
        }
        if (R.bounded([box1[0], box1[1] + box1[3]], [minX, minY], [maxX, maxY])) {
            return true;
        }
        // check one corner of box2 against box1 for the ""
        minX = box1[0];
        minY = box1[1];        
        maxX = box1[0] + box1[2];
        maxY = box1[1] + box1[3];
        if (R.bounded([box2[0], box2[1]], [minX, minY], [maxX, maxY])) {
            return true;
        }
        return false;
    }

    /**
     * 'copy' pass: Render into g-buffers, update light datastructure
     */
    R.pass_copy_tile.render = function(state) {
        // * Bind the framebuffer R.pass_copy_tile.fbo
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_copy_tile.fbo);

        // * Clear screen using R.progClear
        renderFullScreenQuad(R.progClear);
        // * Clear depth buffer to value 1.0 using gl.clearDepth and gl.clear
        gl.clearDepth(1.0);
        // http://webgl.wikia.com/wiki/Clear
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        // * "Use" the program R.progCopy.prog
        gl.useProgram(R.progCopy.prog);

        var m = state.cameraMat.elements;
        // * Upload the camera matrix m to the uniform R.progCopy.u_cameraMat
        //   using gl.uniformMatrix4fv
        gl.uniformMatrix4fv(R.progCopy.u_cameraMat, gl.FALSE, m);

        // * Draw the scene
        drawScene(state, R.progCopy);

        // update the light datastructure

        if (!NUM_TILES_WIDE || !NUM_TILES_TALL) {
            NUM_TILES_WIDE = Math.floor((width + TILE_SIZE - 1) / TILE_SIZE);
            NUM_TILES_TALL = Math.floor((height + TILE_SIZE - 1) / TILE_SIZE);
            NUM_TILES = NUM_TILES_WIDE * NUM_TILES_TALL;
        }

        // preallocate
        var lightData = new Float32Array(width * height * 4);

        var lightScissorBox = [0, 0, 0, 0];
        var tileBox = [0, 0, 0, 0];

        var rowStart = 0;
        var rowOffset = 0;
        var numLights = 0;

        var lightColIndex = 0;
        var lightPosIndex = 0;
        
        var xi = 0;
        var x = 0;
        var j = 0;
        var lightIdx = 0;

        if (cfg.sortLightsBeforeTiling) {
            R.sortLightsByZDepth(state);
        }

        var lightColorOffset = width * 4 * (TILE_SIZE / 2);

        // insert the light lists per tile
        // for simplicity in indexing, this ONLY works for MAX_LIGHTS < TILE_SIZE
        for (var y = 0; y < height; y += TILE_SIZE) {
            xi = 0;
            for (x = 0; x < width; x += TILE_SIZE) {
                // compute start index for this tile
                rowStart = xi + (y * width * 4);
                rowOffset = 0;;

                xi += TILE_SIZE * 4;

                // compute tile 1's box in pix coordinates. same format as what
                // getScissorForLight returns.
                // x, y, width, height
                // check against each light's scissor box
                tileBox = [x, y, TILE_SIZE, TILE_SIZE];
                numLights = 0;
                for (j = 0; j < R.NUM_LIGHTS; j++) {
                    lightIdx = j;
                    if (cfg.sortLightsBeforeTiling) {
                        lightIdx = R.lights_z_sorted[j][1];
                    }

                    // check each light's scissor box against this tile's box
                    lightScissorBox = getScissorForLight(state.viewMat,
                        state.projMat, R.lights[lightIdx]);
                    if (!lightScissorBox) continue;
                    if (R.boxOverlap(tileBox, lightScissorBox)) {
                        lightColIndex = rowStart + rowOffset + lightColorOffset;
                        lightPosIndex = rowStart + rowOffset;

                        // insert color
                        lightData[lightColIndex]     = R.lights[lightIdx].col[0];
                        lightData[lightColIndex + 1] = R.lights[lightIdx].col[1];
                        lightData[lightColIndex + 2] = R.lights[lightIdx].col[2];
                        lightData[lightColIndex + 3] = 1;

                        // insert radius and direction
                        lightData[lightPosIndex]     = R.lights[lightIdx].pos[0];
                        lightData[lightPosIndex + 1] = R.lights[lightIdx].pos[1];
                        lightData[lightPosIndex + 2] = R.lights[lightIdx].pos[2];
                        lightData[lightPosIndex + 3] = R.lights[lightIdx].rad;

                        rowOffset += 4; // lightLists is a bunch of vec4s
                        numLights++;

                        // if necessary, move down a row
                        if (rowOffset > TILE_SIZE * 4) {
                            rowOffset = 0;
                            rowStart += width * 4;
                        }
                    }

                    if (numLights >= MAX_LIGHTS_PER_TILE) break;

                }
                if (numLights < MAX_LIGHTS_PER_TILE) {
                    // add a NULL light pos/radius (radius = -1) to indicate the end of list
                    lightData[lightPosIndex]     = 0;
                    lightData[lightPosIndex + 1] = 0;
                    lightData[lightPosIndex + 2] = 10000000.0;            
                    lightData[lightPosIndex + 3] = -1;
                }

                //lightData[lightDataIndex + 2] = 1;              // debug
                //lightData[lightDataIndex + width * 4 + 2] = 1;  // debug
                //lightData[lightDataIndex + 3] = 1;              // debug
                //lightData[lightDataIndex + width * 4 + 3] = 1;  // debug
            }
        }

        gl.bindTexture(gl.TEXTURE_2D, R.pass_copy_tile.gbufs[4]); // light params
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA,
            gl.FLOAT, lightData);
        gl.bindTexture(gl.TEXTURE_2D, null);
    }

    R.sortLightsByZDepth = function(state) {
        // build R.lights_z_sorted (unsorted)
        var pos_camSpace = new THREE.Vector4(0, 0, 0, 1);
        for (var i = 0; i < R.NUM_LIGHTS; i++) {
            pos_camSpace.x = R.lights[i].pos[0];
            pos_camSpace.y = R.lights[i].pos[1];
            pos_camSpace.z = R.lights[i].pos[2];
            pos_camSpace.w = 1.0;
            pos_camSpace.applyMatrix4(state.viewMat);
            pos_camSpace.applyMatrix4(state.projMat);
            pos_camSpace.divideScalar(pos_camSpace.w);
            // we want negative values (light behind camera) to not even get considered.
            if (pos_camSpace.z < 0.0) {
                pos_camSpace.z += 10000.0;
            }           
            R.lights_z_sorted[i] = [pos_camSpace.z, i];
        }
        
        // sort R.lights_z_sorted
        R.lights_z_sorted.sort(function(a, b) {
            return a[0] - b[0];
        });
        
    }

    var bindTexturesForLightPassTiled = function(prog) {
        gl.useProgram(prog.prog);

        // * Bind all of the g-buffers and depth buffer as texture uniform
        //   inputs to the shader
        for (var i = 0; i < R.NUM_GBUFFERS + 1; i++) {
            if (!prog.u_gbufs[i]) {
                gl.activeTexture(gl['TEXTURE' + i]);
                gl.bindTexture(gl.TEXTURE_2D, R.pass_copy_tile.depthTex);
                gl.uniform1i(prog.u_depth, i);
                return;
            }
            gl.activeTexture(gl['TEXTURE' + i]);
            gl.bindTexture(gl.TEXTURE_2D, R.pass_copy_tile.gbufs[i]);
            gl.uniform1i(prog.u_gbufs[i], i);
        }
        gl.activeTexture(gl['TEXTURE' + (R.NUM_GBUFFERS + 1)]);
        gl.bindTexture(gl.TEXTURE_2D, R.pass_copy_tile.depthTex);
        gl.uniform1i(prog.u_depth, (R.NUM_GBUFFERS + 1));
    };

    /**
     * debug
     */
    R.pass_debug_tile.render = function(state) {
        // * Unbind any framebuffer, so we can write to the screen
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);

        // * Bind/setup the debug "lighting" pass
        // * Tell shader which debug view to use
        bindTexturesForLightPassTiled(R.prog_DebugTiling);

        gl.uniform1i(R.prog_DebugTiling.u_width, width);  
        gl.uniform1i(R.prog_DebugTiling.u_height, height);
        gl.uniform1i(R.prog_DebugTiling.u_tileSize, TILE_SIZE);
        gl.uniform1i(R.prog_DebugTiling.u_numLightsMax, MAX_LIGHTS_PER_TILE);

        // * Render a fullscreen quad to perform shading on
        renderFullScreenQuad(R.prog_DebugTiling);
    }

    /**
     * 'deferred' pass: render all the tiles. no need to accumulate lights!
     */
    R.pass_deferred_tile.render = function(state) { // "pass 2"
        // * Bind R.pass_deferred_tile.fbo to write into for later postprocessing
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_deferred_tile.fbo);

        // * Clear depth to 1.0 and color to black
        gl.clearColor(0.0, 0.0, 0.0, 0.0);
        gl.clearDepth(1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        // Enable blending and use gl.blendFunc to blend with:
        //   color = 1 * src_color + 1 * dst_color
        //   goal is to blend each lighting pass into one beautiful frame buffer
        // still need to blend in the ambient pass!
        gl.enable(gl.BLEND);
        gl.blendFunc(gl.ONE, gl.ONE);

        // * Bind/setup the ambient pass, and render using fullscreen quad
        bindTexturesForLightPassTiled(R.prog_Ambient);
        renderFullScreenQuad(R.prog_Ambient);

        // * Bind/setup the Blinn-Phong pass, and render using fullscreen quad
        bindTexturesForLightPassTiled(R.prog_BlinnPhongTiling);

        
        gl.uniform3fv(R.prog_BlinnPhongTiling.u_camPos, state.cameraPos.toArray());
        gl.uniform1i(R.prog_BlinnPhongTiling.u_width, width);
        gl.uniform1i(R.prog_BlinnPhongTiling.u_height, height);
        gl.uniform1i(R.prog_BlinnPhongTiling.u_tileSize, TILE_SIZE);
        gl.uniform1i(R.prog_BlinnPhongTiling.u_numLightsMax, MAX_LIGHTS_PER_TILE); 

        renderFullScreenQuad(R.prog_BlinnPhongTiling);

        // Disable blending so that it doesn't affect other code
        gl.disable(gl.BLEND);
    };

    /**
     * 'copy' pass: Render into g-buffers
     */
    R.pass_copy.render = function(state) { // "pass 1"
        // * Bind the framebuffer R.pass_copy.fbo
        // TODO: ^
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_copy.fbo);

        // * Clear screen using R.progClear
        renderFullScreenQuad(R.progClear);
        // * Clear depth buffer to value 1.0 using gl.clearDepth and gl.clear
        // TODO: ^
        gl.clearDepth(1.0);
        // TODO: ^
        // http://webgl.wikia.com/wiki/Clear
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        // * "Use" the program R.progCopy.prog
        // TODO: ^
        gl.useProgram(R.progCopy.prog);

        // TODO: Write glsl/copy.frag.glsl

        var m = state.cameraMat.elements;
        // * Upload the camera matrix m to the uniform R.progCopy.u_cameraMat
        //   using gl.uniformMatrix4fv
        // TODO: ^
        gl.uniformMatrix4fv(R.progCopy.u_cameraMat, gl.FALSE, m);

        // * Draw the scene
        drawScene(state, R.progCopy);

        // testing updating textures with an array during runtime
        //gl.bindTexture(gl.TEXTURE_2D, R.pass_copy.gbufs[0]); // texture mapped color
        //var hdiv2 = height;//height / 2; 
        //var data = new Float32Array(width * hdiv2 * 4);
        //for (var i = 0; i < width * hdiv2 * 4; i += 4) {
        //    data[i] = 1.0;
        //    data[i + 1] = 0.0;
        //    data[i + 2] = 0.0;
        //    data[i + 3] = 1.0;
        //}

        //gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, hdiv2, 0, gl.RGBA, gl.FLOAT, data);
        //gl.bindTexture(gl.TEXTURE_2D, null);
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
     * 'copy' pass: Render into compressed g-buffers
     */
    R.pass_copy_compressed.render = function(state) { // "pass 1"
        // * Bind the framebuffer R.pass_copy.fbo
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_copy_compressed.fbo);

        // * Clear screen using R.progClear
        renderFullScreenQuad(R.progClearCompressed);
        // * Clear depth buffer to value 1.0 using gl.clearDepth and gl.clear
        gl.clearDepth(1.0);
        // http://webgl.wikia.com/wiki/Clear
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        // * "Use" the program R.progCopyCompressed.prog
        gl.useProgram(R.progCopyCompressed.prog);

        var m = state.cameraMat.elements;
        // * Upload the camera matrix m to the uniform R.progCopyCompressed.u_cameraMat
        //   using gl.uniformMatrix4fv
        gl.uniformMatrix4fv(R.progCopyCompressed.u_cameraMat, gl.FALSE, m);

        // * Draw the scene
        drawScene(state, R.progCopyCompressed);
    };

    var drawScene = function(state, prog) {
        for (var i = 0; i < state.models.length; i++) {
            var m = state.models[i];

            // If you want to render one model many times, note:
            // readyModelForDraw only needs to be called once.
            readyModelForDraw(prog, m);

            drawReadyModel(m);
        }
    };

    R.pass_debug_compressed.render = function(state) {
        // * Unbind any framebuffer, so we can write to the screen
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);

        // * Bind/setup the debug "lighting" pass
        // * Tell shader which debug view to use
        bindTexturesForLightPassCompressed(R.prog_DebugCompressed);
        gl.uniform1i(R.prog_DebugCompressed.u_debug, cfg.debugView);

        // upload the inverse camera matrix
        var invThreejsMat = new THREE.Matrix4();
        invThreejsMat.copy(state.cameraMat);
        invThreejsMat.getInverse(invThreejsMat);

        //var ID = new THREE.Matrix4;
        //ID.multiplyMatrices(invThreejsMat, state.cameraMat);

        var m = invThreejsMat.elements;     
        gl.uniformMatrix4fv(R.prog_DebugCompressed.u_invCameraMat, gl.FALSE, m);

        // * Render a fullscreen quad to perform shading on
        renderFullScreenQuad(R.prog_DebugCompressed);
    };

    R.pass_debug.debugScissor = function(state) {
        // * Unbind any framebuffer, so we can write to the screen
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);

        renderFullScreenQuad(R.progClear);
        // * Clear depth buffer to value 1.0 using gl.clearDepth and gl.clear
        gl.clearDepth(1.0);
        // http://webgl.wikia.com/wiki/Clear
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        gl.enable(gl.BLEND);
        gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

        gl.enable(gl.SCISSOR_TEST);
        var numLights = R.lights.length;
        for (var i = 0; i < numLights; i++) {
            var sc = getScissorForLight(state.viewMat, state.projMat, R.lights[i]);
            if (sc == null) {
                continue;
            }
            gl.scissor(sc[0], sc[1], sc[2], sc[3]);
            renderFullScreenQuad(R.progRed);
        }
        gl.disable(gl.BLEND);
        gl.disable(gl.SCISSOR_TEST);
    };    

    /**
     * 'deferred' pass: Add lighting results for each individual light
     */
    R.pass_deferred.render = function(state) { // "pass 2"
        // * Bind R.pass_deferred.fbo to write into for later postprocessing
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_deferred.fbo);

        // * Clear depth to 1.0 and color to black
        gl.clearColor(0.0, 0.0, 0.0, 0.0);
        gl.clearDepth(1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        // * _ADD_ together the result of each lighting pass

        // Enable blending and use gl.blendFunc to blend with:
        //   color = 1 * src_color + 1 * dst_color
        //   goal is to blend each lighting pass into one beautiful frame buffer
        // TODO: ^
        gl.enable(gl.BLEND);
        gl.blendFunc(gl.ONE, gl.ONE);

        // * Bind/setup the ambient pass, and render using fullscreen quad
        bindTexturesForLightPass(R.prog_Ambient);
        renderFullScreenQuad(R.prog_Ambient);

        // * Bind/setup the Blinn-Phong pass, and render using fullscreen quad
        bindTexturesForLightPass(R.prog_BlinnPhong_PointLight);

        // TODO: add a loop here, over the values in R.lights, which sets the
        //   uniforms R.prog_BlinnPhong_PointLight.u_lightPos/Col/Rad etc.,
        //   then does renderFullScreenQuad(R.prog_BlinnPhong_PointLight).
        // blinn phong needs to know camera position
        gl.uniform3fv(R.prog_BlinnPhong_PointLight.u_camPos, state.cameraPos.toArray());
        // TODO: In the lighting loop, use the scissor test optimization
        // Enable gl.SCISSOR_TEST, render all lights, then disable it.
        //
        // getScissorForLight returns null if the scissor is off the screen.
        // Otherwise, it returns an array [xmin, ymin, width, height].
        //
        //   var sc = getScissorForLight(state.viewMat, state.projMat, light);

        if (cfg.enableScissor) {
            gl.enable(gl.SCISSOR_TEST);
        }

        var numLights = R.lights.length;
        for (var i = 0; i < numLights; i++) {
            if (cfg.enableScissor) {
                var sc = getScissorForLight(state.viewMat, state.projMat, R.lights[i]);
                if (sc == null) {
                    continue;
                }            
                gl.scissor(sc[0], sc[1], sc[2], sc[3]);
            }

            gl.uniform3fv(R.prog_BlinnPhong_PointLight.u_lightPos, R.lights[i].pos);
            gl.uniform3fv(R.prog_BlinnPhong_PointLight.u_lightCol, R.lights[i].col);
            gl.uniform1f(R.prog_BlinnPhong_PointLight.u_lightRad, R.lights[i].rad);

            renderFullScreenQuad(R.prog_BlinnPhong_PointLight);
        }

        if (cfg.enableScissor) {
            gl.disable(gl.SCISSOR_TEST);
        }

        // Disable blending so that it doesn't affect other code
        gl.disable(gl.BLEND);
    };

    /**
     * 'deferred' pass: Add lighting results for each individual light
     */
    R.pass_toon.render = function(state) { // "pass 2"
        // * Bind R.pass_deferred.fbo to write into for later postprocessing
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_deferred.fbo);

        // * Clear depth to 1.0 and color to black
        gl.clearColor(0.0, 0.0, 0.0, 0.0);
        gl.clearDepth(1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        // * _ADD_ together the result of each lighting pass

        // Enable blending and use gl.blendFunc to blend with:
        //   color = 1 * src_color + 1 * dst_color
        //   goal is to blend each lighting pass into one beautiful frame buffer
        gl.enable(gl.BLEND);
        gl.blendFunc(gl.ONE, gl.ONE);

        // * Bind/setup the ambient pass, and render using fullscreen quad
        bindTexturesForLightPass(R.prog_ToonAmbient);
        renderFullScreenQuad(R.prog_ToonAmbient);

        // * Bind/setup the Blinn-Phong pass, and render using fullscreen quad
        bindTexturesForLightPass(R.prog_Toon);

        gl.uniform3fv(R.prog_Toon.u_camPos, state.cameraPos.toArray());

        if (cfg.enableScissor) {
            gl.enable(gl.SCISSOR_TEST);
        }

        var numLights = R.lights.length;
        for (var i = 0; i < numLights; i++) {
            if (cfg.enableScissor) {
                var sc = getScissorForLight(state.viewMat, state.projMat, R.lights[i]);
                if (sc == null) {
                    continue;
                }            
                gl.scissor(sc[0], sc[1], sc[2], sc[3]);
            }

            gl.uniform3fv(R.prog_Toon.u_lightPos, R.lights[i].pos);
            gl.uniform3fv(R.prog_Toon.u_lightCol, R.lights[i].col);
            gl.uniform1f(R.prog_Toon.u_lightRad, R.lights[i].rad);

            renderFullScreenQuad(R.prog_Toon);
        }

        if (cfg.enableScissor) {
            gl.disable(gl.SCISSOR_TEST);
        }

        // Disable blending so that it doesn't affect other code
        gl.disable(gl.BLEND);
    };

    /**
     * 'deferred' pass: Add lighting results for each individual light
     */
    R.pass_deferred_compressed.render = function(state) { // "pass 2"
        // * Bind R.pass_deferred.fbo to write into for later postprocessing
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_deferred_compressed.fbo);

        // * Clear depth to 1.0 and color to black
        gl.clearColor(0.0, 0.0, 0.0, 0.0);
        gl.clearDepth(1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        // * _ADD_ together the result of each lighting pass

        // Enable blending and use gl.blendFunc to blend with:
        //   color = 1 * src_color + 1 * dst_color
        //   goal is to blend each lighting pass into one beautiful frame buffer
        gl.enable(gl.BLEND);
        gl.blendFunc(gl.ONE, gl.ONE);

        // * Bind/setup the ambient pass, and render using fullscreen quad
        bindTexturesForLightPassCompressed(R.prog_AmbientCompressed);
        renderFullScreenQuad(R.prog_AmbientCompressed);

        // * Bind/setup the Blinn-Phong pass, and render using fullscreen quad
        bindTexturesForLightPassCompressed(R.prog_BlinnPhong_PointLightCompressed);

        gl.uniform3fv(R.prog_BlinnPhong_PointLightCompressed.u_camPos, state.cameraPos.toArray());

        // upload the inverse camera matrix
        var invThreejsMat = new THREE.Matrix4();
        invThreejsMat.copy(state.cameraMat);
        invThreejsMat.getInverse(invThreejsMat);

        var m = invThreejsMat.elements;     
        gl.uniformMatrix4fv(R.prog_BlinnPhong_PointLightCompressed.u_invCameraMat, gl.FALSE, m);

        if (cfg.enableScissor) {
            gl.enable(gl.SCISSOR_TEST);
        }

        var numLights = R.lights.length;
        for (var i = 0; i < numLights; i++) {
            if (cfg.enableScissor) {
                var sc = getScissorForLight(state.viewMat, state.projMat, R.lights[i]);
                if (sc == null) {
                    continue;
                }            
                gl.scissor(sc[0], sc[1], sc[2], sc[3]);
            }

            gl.uniform3fv(R.prog_BlinnPhong_PointLightCompressed.u_lightPos, R.lights[i].pos);
            gl.uniform3fv(R.prog_BlinnPhong_PointLightCompressed.u_lightCol, R.lights[i].col);
            gl.uniform1f(R.prog_BlinnPhong_PointLightCompressed.u_lightRad, R.lights[i].rad);

            renderFullScreenQuad(R.prog_BlinnPhong_PointLightCompressed);
        }

        if (cfg.enableScissor) {
            gl.disable(gl.SCISSOR_TEST);
        }

        // Disable blending so that it doesn't affect other code
        gl.disable(gl.BLEND);
    };

    var bindTexturesForLightPass = function(prog) {
        gl.useProgram(prog.prog);

        // testing updating textures with an array during runtime
        //gl.bindTexture(gl.TEXTURE_2D, R.pass_copy.gbufs[0]); // texture mapped color
        //var hdiv2 = height;//height / 2; 
        //var data = new Float32Array(width * hdiv2 * 4);
        //for (var i = 0; i < width * hdiv2 * 4; i += 4) {
        //    data[i] = 1.0;
        //    data[i + 1] = 0.0;
        //    data[i + 2] = 0.0;
        //    data[i + 3] = 1.0;
        //}

        //gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, hdiv2, 0, gl.RGBA, gl.FLOAT, data);
        //gl.bindTexture(gl.TEXTURE_2D, null);

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

    var bindTexturesForLightPassCompressed = function(prog) {
        gl.useProgram(prog.prog);

        // * Bind all of the g-buffers and depth buffer as texture uniform
        //   inputs to the shader
        for (var i = 0; i < R.NUM_GBUFFERS_COMPRESSED; i++) {
            gl.activeTexture(gl['TEXTURE' + i]);
            gl.bindTexture(gl.TEXTURE_2D, R.pass_copy_compressed.gbufs[i]);
            gl.uniform1i(prog.u_gbufs[i], i);
        }
        gl.activeTexture(gl['TEXTURE' + R.NUM_GBUFFERS_COMPRESSED]);
        gl.bindTexture(gl.TEXTURE_2D, R.pass_copy_compressed.depthTex);
        gl.uniform1i(prog.u_depth, R.NUM_GBUFFERS_COMPRESSED);
    };    

    /**
     * 'post1' pass: Perform (first) pass of post-processing
     */
    R.pass_post1.render = function(state, tex) {
        // * Unbind any existing framebuffer (if there are no more passes)
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);

        // * Clear the framebuffer depth to 1.0
        gl.clearDepth(1.0);
        gl.clear(gl.DEPTH_BUFFER_BIT);

        // * Bind the postprocessing shader program
        gl.useProgram(R.progPost1.prog);

        // * Bind the deferred pass's color output as a texture input
        // Set gl.TEXTURE0 as the gl.activeTexture unit
        // TODO: ^
        gl.activeTexture(gl.TEXTURE0);
        // Bind the TEXTURE_2D, R.pass_deferred.colorTex to the active texture unit
        // TODO: ^
        gl.bindTexture(gl.TEXTURE_2D, tex);
        // Configure the R.progPost1.u_color uniform to point at texture unit 0
        gl.uniform1i(R.progPost1.u_color, 0);
        gl.uniform1i(R.progPost1.u_bloom, cfg.enableBloom);

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
        var positions = new Float32Array([
            -1.0, -1.0, 0.0,
             1.0, -1.0, 0.0,
            -1.0,  1.0, 0.0,
             1.0,  1.0, 0.0
        ]);

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
            gl.enableVertexAttribArray(prog.a_position);

            // Use gl.vertexAttribPointer to tell WebGL the type/layout for
            // prog.a_position's access pattern.
            gl.vertexAttribPointer(prog.a_position, 3, gl.FLOAT, false, 0, 0);

            // Use gl.drawArrays (or gl.drawElements) to draw your quad.
            gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

            // Unbind the array buffer.
            gl.bindBuffer(gl.ARRAY_BUFFER, null);
        };
    })();
})();
