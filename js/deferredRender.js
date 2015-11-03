(function() {
    'use strict';
    // deferredSetup.js must be loaded first

    R.deferredRender = function(state) {
        if (!aborted && (
            !R.progCopy ||
            !R.progRed ||
            !R.progClear ||
            !R.prog_Ambient ||
            !R.prog_BlinnPhong_PointLight ||
            !R.prog_Debug ||
            !R.progPost1)) {
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
        }
 */
        R.pass_copy.render(state);

        if (cfg && cfg.debugView >= 0) {
            // Do a debug render instead of a regular render
            // Don't do any post-processing in debug mode
            R.pass_debug.render(state);
        }
        else if(cfg.debugScissor){
            R.pass_scissor.render(state);
        }
        else {
            // * Deferred pass and postprocessing pass(es)
            R.pass_deferred.render(state, cfg.tiledBased);
            
            var previousPass = R.pass_deferred;
            if(cfg.enableToonShade){
                R.pass_toonShade.render(state, previousPass);
                previousPass = R.pass_toonShade;
            }
            if(cfg.enableMBlur){
                R.pass_mBlur.render(state, previousPass);
                previousPass = R.pass_mBlur;
            }
            
            R.pass_post1.render(state, previousPass);
        }
    };

    /**
     * 'copy' pass: Render into g-buffers
     */
    R.pass_copy.render = function(state) {
        // * Bind the framebuffer R.pass_copy.fbo
        // TODO: ^
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_copy.fbo);

        // * Clear screen using R.progClear
        renderFullScreenQuad(R.progClear);
        // * Clear depth buffer to value 1.0 using gl.clearDepth and gl.clear
        // TODO: ^
        // TODO: ^
        gl.clearDepth(1.0);
        gl.clear(gl.DEPTH_BUFFER_BIT);

        // * "Use" the program R.progCopy.prog
        // TODO: ^
        // TODO: Write glsl/copy.frag.glsl
        
        gl.useProgram(R.progCopy.prog);

        var m = state.cameraMat.elements;
        // * Upload the camera matrix m to the uniform R.progCopy.u_cameraMat
        //   using gl.uniformMatrix4fv
        // TODO: ^
        
        gl.uniformMatrix4fv(R.progCopy.u_cameraMat, gl.FALSE, m);

        // * Draw the scene
        drawScene(state);
    };

    var drawScene = function(state) {
        for (var i = 0; i < state.models.length; i++) {
            var m = state.models[i];

            gl.uniform1i(R.progCopy.u_specularExp, m.specularExp);
            gl.uniform1f(R.progCopy.u_specularCoeff, m.specularCoeff);
            // If you want to render one model many times, note:
            // readyModelForDraw only needs to be called once.
            readyModelForDraw(R.progCopy, m);

            drawReadyModel(m);
        }
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
    
    R.pass_scissor.render = function(state){
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);

        // * Clear depth to 1.0 and color to black
        gl.clearColor(0.0, 0.0, 0.0, 0.0);
        gl.clearDepth(1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        // Enable blending and use gl.blendFunc to blend with:
        //   color = 1 * src_color + 1 * dst_color
        // TODO: ^
        gl.enable( gl.BLEND );
        gl.blendEquation( gl.FUNC_ADD );
        gl.blendFunc( gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA );
        
        //draw bg ambient
        bindTexturesForLightPass(R.prog_Ambient);
        renderFullScreenQuad(R.prog_Ambient);
        
        gl.enable( gl.SCISSOR_TEST );
            
        for (var i = 0; i < R.lights.length; i++) {
            var light = R.lights[i];
            var sc = getScissorForLight(state.viewMat, state.projMat, light);
            if(sc != null){
                gl.scissor(sc[0], sc[1], sc[2], sc[3]);
                renderFullScreenQuad(R.prog_scissor);
            }
        }

        // Disable blending so that it doesn't affect other code
        gl.disable(gl.SCISSOR_TEST);
        gl.disable(gl.BLEND);
    }

    /**
     * 'deferred' pass: Add lighting results for each individual light
     */
    R.pass_deferred.render = function(state, tileBased) {
        // * Bind R.pass_deferred.fbo to write into for later postprocessing
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_deferred.fbo);

        // * Clear depth to 1.0 and color to black
        gl.clearColor(0.0, 0.0, 0.0, 0.0);
        gl.clearDepth(1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        // * _ADD_ together the result of each lighting pass

        // Enable blending and use gl.blendFunc to blend with:
        //   color = 1 * src_color + 1 * dst_color
        // TODO: ^
        gl.enable( gl.BLEND );
        gl.blendEquation( gl.FUNC_ADD );
        gl.blendFunc( gl.ONE, gl.ONE );

        
        // * Bind/setup the ambient pass, and render using fullscreen quad
        bindTexturesForLightPass(R.prog_Ambient);
        renderFullScreenQuad(R.prog_Ambient);
        
        // TODO: add a loop here, over the values in R.lights, which sets the
        //   uniforms R.prog_BlinnPhong_PointLight.u_lightPos/Col/Rad etc.,
        //   then does renderFullScreenQuad(R.prog_BlinnPhong_PointLight).

        // TODO: In the lighting loop, use the scissor test optimization
        // Enable gl.SCISSOR_TEST, render all lights, then disable it.
        //
        // getScissorForLight returns null if the scissor is off the screen.
        // Otherwise, it returns an array [xmin, ymin, width, height].
        //
        //   var sc = getScissorForLight(state.viewMat, state.projMat, light);

        gl.enable( gl.SCISSOR_TEST );
        
        if(tileBased){
            bindTexturesForLightPass(R.prog_tilebased_light);
            var p = R.prog_tilebased_light;
            
            //pack light
            var indexList = [];
            for (var i = 0; i < p.total; i++) {
                indexList.push([]);
            }
              
            var indexSize = 0;
            for (i = 0; i < R.lights.length; i++) {
                var light = R.lights[i];
                    
                //push into the global light list
                p.lightPos[i*3] = light.pos[0];
                p.lightPos[i*3 + 1] = light.pos[1];
                p.lightPos[i*3 + 2] = light.pos[2];

                var sc = getScissorForLight(state.viewMat, state.projMat, light);
                if(sc != null){
                    
                    //fill the light index list
                    var xStart = Math.floor(sc[0] / p.tileSize);
                    var xEnd = xStart + Math.ceil(sc[2] / p.tileSize);
                    var yStart = Math.floor(sc[1] / p.tileSize);
                    var yEnd = yStart + Math.ceil(sc[3] / p.tileSize);
                    
                    for(var y = yStart; y < yEnd; y++){
                        for(var x = xStart; x < xEnd; x++){
                            indexList[y * p.tx + x].push(i);
                            indexSize++;
                        }
                    }
                }
            }

            var indexListTData = new Float32Array(indexSize * 3);
            var firstIndex = 0;
            var lastIndex = 0;
            for (i = 0; i < p.total; i++) {
                var tmp = indexList[i];
                for(var j = 0; j < tmp.length; j++){
                    indexListTData[lastIndex * 3] = tmp[j];
                    indexListTData[lastIndex * 3 + 1] = 0;
                    indexListTData[lastIndex * 3 + 2] = 0;
                    lastIndex++;
                }
                
                p.lightOffset[i] = firstIndex;
                p.lightNo[i] = tmp.length;
                firstIndex = lastIndex;
            }
            //pack them!
            var textureNo = R.NUM_GBUFFERS + 1;
            gl.activeTexture(gl['TEXTURE' + textureNo]);
            gl.bindTexture(gl.TEXTURE_2D, p.lightPosTexture);
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, R.lights.length, 1, 0, gl.RGB, gl.FLOAT, p.lightPos);
            gl.uniform1i(R.prog_tilebased_light.u_lightPos, textureNo);
            
            textureNo++;
            gl.activeTexture(gl['TEXTURE' + textureNo]);
            gl.bindTexture(gl.TEXTURE_2D, p.lightColTexture);
            gl.uniform1i(R.prog_tilebased_light.u_lightCol, textureNo);
            
            textureNo++;
            gl.activeTexture(gl['TEXTURE' + textureNo]);
            gl.bindTexture(gl.TEXTURE_2D, p.lightListTexture);
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, indexListTData.length/3, 1, 0, gl.RGB, gl.FLOAT, indexListTData);
            gl.uniform1i(R.prog_tilebased_light.u_lightList, textureNo);
            
            gl.uniform1f(R.prog_tilebased_light.u_lightOffsetLength, indexListTData.length/3);
            gl.uniform1f(p.u_totalLight, R.lights.length);
             
            var viewpos = new Float32Array([state.cameraPos.x, state.cameraPos.y, state.cameraPos.z]);
            gl.uniform3fv(R.prog_tilebased_light.u_viewPos, viewpos);
        
            for(var i = 0; i < p.tx; i++){
                for(var j = 0; j < p.ty; j++){
                    gl.scissor(i * p.tileSize, j * p.tileSize, p.tileSize, p.tileSize);
                    
                    gl.uniform1i(R.prog_tilebased_light.u_lightOffset, p.lightOffset[j * p.tx + i]);
                    gl.uniform1i(R.prog_tilebased_light.u_lightNo, p.lightNo[j * p.tx + i]);
                    renderFullScreenQuad(R.prog_tilebased_light);
                }
            }
        }
        else{
            bindTexturesForLightPass(R.prog_BlinnPhong_PointLight);
            
            var viewpos = new Float32Array([state.cameraPos.x, state.cameraPos.y, state.cameraPos.z]);
            gl.uniform3fv(R.prog_BlinnPhong_PointLight.u_viewPos, viewpos);
            
            for (var i = 0; i < R.lights.length; i++) {
                var light = R.lights[i];
                
                //TODO: Fix this.
                var sc = getScissorForLight(state.viewMat, state.projMat, light);
                if(sc != null){
                    gl.scissor(sc[0], sc[1], sc[2], sc[3]);
                
                    gl.uniform3fv(R.prog_BlinnPhong_PointLight.u_lightPos, light.pos);
                    gl.uniform3fv(R.prog_BlinnPhong_PointLight.u_lightCol, light.col);
                    gl.uniform1f(R.prog_BlinnPhong_PointLight.u_lightRad, light.rad);
                    
                    renderFullScreenQuad(R.prog_BlinnPhong_PointLight);
                }
            }
    
        }

        // Disable blending so that it doesn't affect other code
        gl.disable( gl.SCISSOR_TEST );
        gl.disable(gl.BLEND);
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

    /**
     * 'post1' pass: Perform (first) pass of post-processing
     */
    R.pass_post1.render = function(state, previousPass) {
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
        // Bind the TEXTURE_2D, R.pass_deferred.colorTex to the active texture unit
        // TODO: ^
        // Configure the R.progPost1.u_color uniform to point at texture unit 0
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, previousPass.colorTex);
        gl.uniform1i(R.progPost1.u_color, 0);

        // * Render a fullscreen quad to perform shading on
        renderFullScreenQuad(R.progPost1);
    };
    
    R.pass_toonShade.render = function(state, previousPass) {
        // * Unbind any existing framebuffer (if there are no more passes)
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_toonShade.fbo);

        // * Clear the framebuffer depth to 1.0
        gl.clearDepth(1.0);
        gl.clear(gl.DEPTH_BUFFER_BIT);

        // * Bind the postprocessing shader program
        gl.useProgram(R.prog_toonShade.prog);

        // * Bind the deferred pass's color output as a texture input
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, previousPass.colorTex);
        gl.uniform1i(R.prog_toonShade.u_color, 0);
        
        gl.activeTexture(gl.TEXTURE1);
        gl.bindTexture(gl.TEXTURE_2D, R.pass_copy.depthTex);
        gl.uniform1i(R.prog_toonShade.u_depth, 1);
        
        gl.uniform1i(R.prog_toonShade.u_width, width);
        gl.uniform1i(R.prog_toonShade.u_height, height);

        // * Render a fullscreen quad to perform shading on
        renderFullScreenQuad(R.prog_toonShade);
    };

    R.pass_mBlur.render = function(state, previousPass) {
        // * Unbind any existing framebuffer (if there are no more passes)
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_mBlur.fbo);

        // * Clear the framebuffer depth to 1.0
        gl.clearDepth(1.0);
        gl.clear(gl.DEPTH_BUFFER_BIT);

        // * Bind the postprocessing shader program
        gl.useProgram(R.prog_mBlur.prog);

        // * Bind the deferred pass's color output as a texture input
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, previousPass.colorTex);
        gl.uniform1i(R.prog_mBlur.u_color, 0);
        
        gl.activeTexture(gl.TEXTURE1);
        gl.bindTexture(gl.TEXTURE_2D, R.pass_copy.depthTex);
        gl.uniform1i(R.prog_mBlur.u_depth, 1);

        var invVProj = new THREE.Matrix4();
        invVProj.getInverse(state.cameraMat);
        gl.uniformMatrix4fv(R.prog_mBlur.u_inverseVProj, gl.FALSE, invVProj.elements);
        gl.uniformMatrix4fv(R.prog_mBlur.u_previousVProj, gl.FALSE, state.prevCameraMat.elements);

        // * Render a fullscreen quad to perform shading on
        renderFullScreenQuad(R.prog_mBlur);
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
            // TODO: ^
            vbo = gl.createBuffer();
            gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
            gl.bufferData(gl.ARRAY_BUFFER, positions, gl.STATIC_DRAW);

            // Bind the VBO as the gl.ARRAY_BUFFER
            // TODO: ^
            // Upload the positions array to the currently-bound array buffer
            // using gl.bufferData in static draw mode.
            // TODO: ^
        };

        return function(prog) {
            if (!vbo) {
                // If the vbo hasn't been initialized, initialize it.
                init();
            }

            // Bind the program to use to draw the quad
            gl.useProgram(prog.prog);
            gl.bindBuffer(gl.ARRAY_BUFFER, vbo);
            gl.enableVertexAttribArray(prog.a_position);
            gl.vertexAttribPointer(prog.a_position, 3, gl.FLOAT, false, 0, 0);
            gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

            // Bind the VBO as the gl.ARRAY_BUFFER
            // TODO: ^
            // Enable the bound buffer as the vertex attrib array for
            // prog.a_position, using gl.enableVertexAttribArray
            // TODO: ^
            // Use gl.vertexAttribPointer to tell WebGL the type/layout for
            // prog.a_position's access pattern.
            // TODO: ^

            // Use gl.drawArrays (or gl.drawElements) to draw your quad.
            // TODO: ^

            // Unbind the array buffer.
            gl.bindBuffer(gl.ARRAY_BUFFER, null);
        };
    })();
})();
