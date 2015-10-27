(function() {
    'use strict';
    // deferredSetup.js must be loaded first
	var statePrevMat = new Float32Array([
            1.0,1.0,1.0,1.0,
			1.0,1.0,1.0,1.0,
			1.0,1.0,1.0,1.0,
			1.0,1.0,1.0,1.0
        ]);
	var prevEye = new Float32Array([0.0,0.0,0.0]);
    R.deferredRender = function(state) {
        if (!aborted && (
            !R.progCopy ||
            !R.progRed ||
            !R.progClear ||
            !R.prog_Ambient ||
            !R.prog_BlinnPhong_PointLight ||
            !R.prog_Debug ||
            !R.progPost1 ||
			!R.progSrcmask||
			!R.progBloomX||
			!R.progBloomY||
			!R.progToon||
			!R.progMotion
		)) {
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
        { // TO_DO: this block should be removed after testing renderFullScreenQuad
            gl.bindFramebuffer(gl.FRAMEBUFFER, null);
            // TO_DO: Implement/test renderFullScreenQuad first
            renderFullScreenQuad(R.progRed);
            return;
        }
*/
        R.pass_copy.render(state);

        if (cfg && cfg.debugView >= 0 && cfg.debugView<=5) {
            // Do a debug render instead of a regular render
            // Don't do any post-processing in debug mode
            R.pass_debug.render(state);
        } else {
            // * Deferred pass and postprocessing pass(es)
            // TODO: uncomment these
            R.pass_deferred.render(state);
			var finalRender = R.pass_deferred.colorTex;
			if(cfg.bloomEffect)
			{
				R.pass_srcmask.render(state);
				R.pass_bloomX.render(state);
				R.pass_bloomY.render(state);
				finalRender = R.pass_bloomY.colorTex;
			}
			else if(cfg.toonEffect)//TODO:later if
			{
				R.pass_toon.render(state);
				finalRender = R.pass_toon.colorTex;
			}
			else if(cfg.motionBlurEffect)
			{
				R.pass_motion.render(state);
				finalRender = R.pass_motion.colorTex;
			}
			R.pass_post1.render(state,finalRender);
            // OPTIONAL TODO: call more postprocessing passes, if any
        }
    };

    /**
     * 'copy' pass: Render into g-buffers
     */
    R.pass_copy.render = function(state) {
        // * Bind the framebuffer R.pass_copy.fbo
        // TO_DO: ^
		gl.bindFramebuffer(gl.FRAMEBUFFER,R.pass_copy.fbo);
        // * Clear screen using R.progClear
        //TO_DO:
		renderFullScreenQuad(R.progClear);
        // * Clear depth buffer to value 1.0 using gl.clearDepth and gl.clear
        // TO_DO: ^
		gl.clearDepth(1.0);
        // TO_DO: ^
		gl.clear(gl.DEPTH_BUFFER_BIT);
        // * "Use" the program R.progCopy.prog
        // TO_DO: ^
        // TODO: Write glsl/copy.frag.glsl
		gl.useProgram(R.progCopy.prog);
		
        var m = state.cameraMat.elements;
        // * Upload the camera matrix m to the uniform R.progCopy.u_cameraMat
        //   using gl.uniformMatrix4fv
        // TO_DO: ^
		gl.uniformMatrix4fv(R.progCopy.u_cameraMat,gl.FALSE,m);
        // * Draw the scene
        drawScene(state);
    };

    var drawScene = function(state) {
        for (var i = 0; i < state.models.length; i++) {
            var m = state.models[i];

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

    /**
     * 'deferred' pass: Add lighting results for each individual light
     */
    R.pass_deferred.render = function(state) {
        // * Bind R.pass_deferred.fbo to write into for later postprocessing
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_deferred.fbo);
		//gl.bindFramebuffer(gl.FRAMEBUFFER, null);
		
        // * Clear depth to 1.0 and color to black
        gl.clearColor(0.0, 0.0, 0.0, 0.0);
        gl.clearDepth(1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        // * _ADD_ together the result of each lighting pass

        // Enable blending and use gl.blendFunc to blend with:
        //   color = 1 * src_color + 1 * dst_color
		//http://learningwebgl.com/blog/?p=859
        // TO_DO: ^ ??? dst_color?
		gl.blendFunc(gl.SRC_ALPHA, gl.ONE);
		gl.enable(gl.BLEND);
        // * Bind/setup the ambient pass, and render using fullscreen quad
        bindTexturesForLightPass(R.prog_Ambient);
        renderFullScreenQuad(R.prog_Ambient);

        // * Bind/setup the Blinn-Phong pass, and render using fullscreen quad
        bindTexturesForLightPass(R.prog_BlinnPhong_PointLight);

        // TO_DO: add a loop here, over the values in R.lights, which sets the
        //   uniforms R.prog_BlinnPhong_PointLight.u_lightPos/Col/Rad etc.,
        //   then does renderFullScreenQuad(R.prog_BlinnPhong_PointLight).
		if(cfg.scissor_test_optimization)
			gl.enable(gl.SCISSOR_TEST);
		//scissor: 118ms->52ms, but , hard edge
		for (var i = 0; i < R.lights.length; i++)
		{
			var l = R.lights[i];
			var eye = [state.cameraPos.x,state.cameraPos.y,state.cameraPos.z];
			
			//if(cfg.scissor_test_optimization)
			var sc = getScissorForLight(state.viewMat, state.projMat, l);
			if((sc!=null)||(!cfg.scissor_test_optimization))
			{
				if(cfg && cfg.debugScissor)
				{
					if(cfg.scissor_test_optimization)
						gl.scissor(sc[0],sc[1],sc[2],sc[3]);
					renderFullScreenQuad(R.progRed);
				}
				else
				{
					if(cfg.scissor_test_optimization)
						gl.scissor(sc[0],sc[1],sc[2],sc[3]);
			
					gl.uniform3fv(R.prog_BlinnPhong_PointLight.u_camPos,eye);
					gl.uniform3fv(R.prog_BlinnPhong_PointLight.u_lightPos, l.pos);
					gl.uniform3fv(R.prog_BlinnPhong_PointLight.u_lightCol, l.col);
					gl.uniform1f(R.prog_BlinnPhong_PointLight.u_lightRad,l.rad);
					gl.uniform1i(R.prog_BlinnPhong_PointLight.u_toon,cfg.toonEffect);
					
					renderFullScreenQuad(R.prog_BlinnPhong_PointLight);
				}
			}
		}
		gl.disable(gl.SCISSOR_TEST);
        // TODO: In the lighting loop, use the scissor test optimization
        // Enable gl.SCISSOR_TEST, render all lights, then disable it.
        //
        // getScissorForLight returns null if the scissor is off the screen.
        // Otherwise, it returns an array [xmin, ymin, width, height].
        //
        //   var sc = getScissorForLight(state.viewMat, state.projMat, light);
			
        // Disable blending so that it doesn't affect other code
        gl.disable(gl.BLEND);
    };
	
    var bindTexturesForLightPass = function(prog) {
        gl.useProgram(prog.prog);

        // * Bind all xof the g-buffers and depth buffer as texture uniform
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
    R.pass_post1.render = function(state,finalRender) {
        // * Unbind any existing framebuffer (if there are no more passes)
        gl.bindFramebuffer(gl.FRAMEBUFFER, null);

        // * Clear the framebuffer depth to 1.0
        gl.clearDepth(1.0);
        gl.clear(gl.DEPTH_BUFFER_BIT);

        // * Bind the postprocessing shader program
        gl.useProgram(R.progPost1.prog);

        // * Bind the deferred pass's color output as a texture input
        // Set gl.TEXTURE0 as the gl.activeTexture unit
        // TO_DO: ^
		gl.activeTexture(gl.TEXTURE0);
        // Bind the TEXTURE_2D, R.pass_deferred.colorTex to the active texture unit
        // TO_DO: ^
		//gl.bindTexture(gl.TEXTURE_2D, R.pass_deferred.colorTex);		
		gl.bindTexture(gl.TEXTURE_2D, finalRender);		
        
		// Configure the R.progPost1.u_color uniform to point at texture unit 0
        gl.uniform1i(R.progPost1.u_color, 0);	
        // * Render a fullscreen quad to perform shading on
        renderFullScreenQuad(R.progPost1);
    };
	
    R.pass_srcmask.render = function(state) {
        // * Unbind any existing framebuffer (if there are no more passes)
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_srcmask.fbo);

        // * Clear the framebuffer depth to 1.0
        gl.clearDepth(1.0);
        gl.clear(gl.DEPTH_BUFFER_BIT);

        // * Bind the postprocessing shader program
        gl.useProgram(R.progSrcmask.prog);

        // * Bind the deferred pass's color output as a texture input
        // Set gl.TEXTURE0 as the gl.activeTexture unit
        // TO_DO: ^
		gl.activeTexture(gl.TEXTURE0);
        // Bind the TEXTURE_2D, R.pass_deferred.colorTex to the active texture unit
        // TO_DO: ^
		gl.bindTexture(gl.TEXTURE_2D, R.pass_deferred.colorTex);		
        // Configure the R.progPost1.u_color uniform to point at texture unit 0
        gl.uniform1i(R.progSrcmask.u_color, 0);	
		gl.uniform1f(R.progSrcmask.u_thresh, 15.0);	
        // * Render a fullscreen quad to perform shading on
        renderFullScreenQuad(R.progSrcmask);
    };
	
    R.pass_bloomX.render = function(state) {
        // * Unbind any existing framebuffer (if there are no more passes)
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_bloomX.fbo);

        // * Clear the framebuffer depth to 1.0
        gl.clearDepth(1.0);
        gl.clear(gl.DEPTH_BUFFER_BIT);

        // * Bind the postprocessing shader program
        gl.useProgram(R.progBloomX.prog);

        // * Bind the deferred pass's color output as a texture input
        // Set gl.TEXTURE0 as the gl.activeTexture unit
        // TO_DO: ^
		gl.activeTexture(gl.TEXTURE0);
        // Bind the TEXTURE_2D, R.pass_deferred.colorTex to the active texture unit
        // TO_DO: ^
		gl.bindTexture(gl.TEXTURE_2D, R.pass_srcmask.colorTex);		
        // Configure the R.progPost1.u_color uniform to point at texture unit 0
        gl.uniform1i(R.progBloomX.u_color, 0);
		var tSize = [width,height];	
		gl.uniform2fv(R.progBloomX.u_texSize,tSize);
        // * Render a fullscreen quad to perform shading on
        renderFullScreenQuad(R.progBloomX);
    };
	
    R.pass_bloomY.render = function(state) {
        // * Unbind any existing framebuffer (if there are no more passes)
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_bloomY.fbo);

        // * Clear the framebuffer depth to 1.0
        gl.clearDepth(1.0);
        gl.clear(gl.DEPTH_BUFFER_BIT);

        // * Bind the postprocessing shader program
        gl.useProgram(R.progBloomY.prog);

        // * Bind the deferred pass's color output as a texture input
        // Set gl.TEXTURE0 as the gl.activeTexture unit
        // TO_DO: ^
		gl.activeTexture(gl.TEXTURE0);
		gl.bindTexture(gl.TEXTURE_2D, R.pass_bloomX.colorTex);	
		
		gl.activeTexture(gl.TEXTURE1);
		gl.bindTexture(gl.TEXTURE_2D, R.pass_deferred.colorTex);	
		
		gl.uniform1i(R.progBloomY.u_color, 0);
		gl.uniform1i(R.progBloomY.u_origCol, 1);
		
		var tSize = [width,height];	
		gl.uniform2fv(R.progBloomY.u_texSize,tSize);
        // * Render a fullscreen quad to perform shading on
        renderFullScreenQuad(R.progBloomY);
    };
	
    R.pass_toon.render = function(state) {
        // * Unbind any existing framebuffer (if there are no more passes)
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_toon.fbo);

        // * Clear the framebuffer depth to 1.0
        gl.clearDepth(1.0);
        gl.clear(gl.DEPTH_BUFFER_BIT);

        // * Bind the postprocessing shader program
        gl.useProgram(R.progToon.prog);

        // * Bind the deferred pass's color output as a texture input
        // Set gl.TEXTURE0 as the gl.activeTexture unit
        // TO_DO: ^
		gl.activeTexture(gl.TEXTURE0);
		gl.bindTexture(gl.TEXTURE_2D, R.pass_deferred.colorTex);		
        // Configure the R.progPost1.u_color uniform to point at texture unit 0
		gl.activeTexture(gl.TEXTURE1);
		gl.bindTexture(gl.TEXTURE_2D, R.pass_copy.depthTex);
		
        gl.uniform1i(R.progToon.u_color, 0);	
        // * Render a fullscreen quad to perform shading on
		gl.uniform1i(R.progToon.u_depthTex, 1);
		gl.uniform1f(R.progToon.u_thresh, 25.0);
		
		var tSize = [width,height];	
		gl.uniform2fv(R.progToon.u_texSize,tSize);
		
        renderFullScreenQuad(R.progToon);
    };

    R.pass_motion.render = function(state) {
        // * Unbind any existing framebuffer (if there are no more passes)
        gl.bindFramebuffer(gl.FRAMEBUFFER, R.pass_motion.fbo);

        // * Clear the framebuffer depth to 1.0
        gl.clearDepth(1.0);
        gl.clear(gl.DEPTH_BUFFER_BIT);

        // * Bind the postprocessing shader program
        gl.useProgram(R.progMotion.prog);

        // * Bind the deferred pass's color output as a texture input
        // Set gl.TEXTURE0 as the gl.activeTexture unit
        // TO_DO: ^
		gl.activeTexture(gl.TEXTURE0);
		gl.bindTexture(gl.TEXTURE_2D, R.pass_deferred.colorTex);	
		//gl.bindTexture(gl.TEXTURE_2D, R.pass_copy.gbufs[0]);	
		
		gl.activeTexture(gl.TEXTURE1);
		gl.bindTexture(gl.TEXTURE_2D, R.pass_copy.gbufs[0]);	
		//gl.bindTexture(gl.TEXTURE_2D, R.pass_copy.gbufs[0]);	
		
		gl.uniform1i(R.progMotion.u_color, 0);
		gl.uniform1i(R.progMotion.u_pos, 1);
		//gl.uniform1i(R.progBloomY.u_origCol, 1);
		
		var tSize = [width,height];	
		gl.uniform2fv(R.progMotion.u_texSize,tSize);
        var m = state.prevCamMat.elements;//state.cameraMat.elements;
		gl.uniformMatrix4fv(R.progMotion.u_cameraMat,gl.FALSE,m);
		//var prevM = state.prevCamMat.elements;
		gl.uniformMatrix4fv(R.progMotion.u_prevMat,gl.FALSE,statePrevMat);
        // * Render a fullscreen quad to perform shading on
		var eye = [state.cameraPos.x,state.cameraPos.y,state.cameraPos.z];
		gl.uniform3fv(R.progMotion.u_crntEye,eye);
		
		gl.uniform3fv(R.progMotion.u_prevEye,prevEye);
		
        renderFullScreenQuad(R.progMotion);
		//if(statePrevMat)
		prevEye = [state.cameraPos.x,state.cameraPos.y,state.cameraPos.z];
		statePrevMat = m;
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
            // TO_DO: ^
			vbo = gl.createBuffer();
            // Bind the VBO as the gl.ARRAY_BUFFER
            // TO_DO: ^
            gl.bindBuffer(gl.ARRAY_BUFFER,vbo);
			// Upload the positions array to the currently-bound array buffer
            // using gl.bufferData in static draw mode.
            // TO_DO: ^
			gl.bufferData(gl.ARRAY_BUFFER,positions,gl.STATIC_DRAW);
        };

        return function(prog) {
            if (!vbo) {
                // If the vbo hasn't been initialized, initialize it.
                init();
            }

            // Bind the program to use to draw the quad
            gl.useProgram(prog.prog);

            // Bind the VBO as the gl.ARRAY_BUFFER
            // TO_DO: ^
            gl.bindBuffer(gl.ARRAY_BUFFER,vbo);
			// Enable the bound buffer as the vertex attrib array for
            // prog.a_position, using gl.enableVertexAttribArray
            // TO_DO: ^
			gl.enableVertexAttribArray(prog.a_position);
            // Use gl.vertexAttribPointer to tell WebGL the type/layout for
            // prog.a_position's access pattern.
            // TO_DO: ^
			gl.vertexAttribPointer(prog.a_position,3,gl.FLOAT,false,0,0);
            // Use gl.drawArrays (or gl.drawElements) to draw your quad.
            // TO_DO: ^
			gl.drawArrays(gl.TRIANGLE_STRIP,0,4);
            // Unbind the array buffer.
            gl.bindBuffer(gl.ARRAY_BUFFER, null);
        };
    })();
})();
