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
            !R.progPost1 ||
            !R.prog_bloom_w||
            !R.prog_toon
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

        //debugger;
        R.pass_copy.render(state);

        if (cfg && cfg.debugView >= 0) {
            // Do a debug render instead of a regular render
            // Don't do any post-processing in debug mode
            R.pass_debug.render(state);
        } 
        
        else if(cfg.debugView<0 && cfg.TwoPassBloom) {
           // R.light_pass.render(state);
            R.pass_deferred.render(state);
        	R.pass_bloom_w.render(state);
        	R.pass_bloom_h.render(state);
        }
          
        else {
            // * Deferred pass and postprocessing pass(es)
           
            R.pass_deferred.render(state);

            R.pass_post1.render(state);
            // OPTIONAL TODO: call more postprocessing passes, if any
        }
    };

    /**
     * 'copy' pass: Render into g-buffers
     */
    R.pass_copy.render = function(state) {
        // * Bind the framebuffer R.pass_copy.fbo
        gl.bindFramebuffer(gl.FRAMEBUFFER,R.pass_copy.fbo);
        // * Clear screen using R.progClear
        renderFullScreenQuad(R.progClear);
        // * Clear depth buffer to value 1.0 using gl.clearDepth and gl.clear
        gl.clearDepth(1.0);
        gl.clear(gl.DEPTH_BUFFER_BIT);

        // * "Use" the program R.progCopy.prog
        gl.useProgram(R.progCopy.prog); 
        var m = state.cameraMat.elements;
        // * Upload the camera matrix m to the uniform R.progCopy.u_cameraMat
        //   using gl.uniformMatrix4fv
        gl.uniformMatrix4fv(R.progCopy.u_cameraMat,false,m);
        gl.uniform3f(R.progCopy.u_spec, cfg.specular,0.0,0.0);
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
        gl.bindFramebuffer(gl.FRAMEBUFFER,  null);

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

        // * Clear depth to 1.0 and color to black
        gl.clearColor(0.0, 0.0, 0.0, 0.0);
        gl.clearDepth(1.0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
        gl.enable(gl.BLEND);
        gl.blendEquation( gl.FUNC_ADD );
        gl.blendFunc(gl.ONE,gl.ONE);
     
        // * Bind/setup the ambient pass, and render using fullscreen quad

        bindTexturesForLightPass(R.prog_Ambient);
        renderFullScreenQuad(R.prog_Ambient);
   
        bindTexturesForLightPass(R.prog_BlinnPhong_PointLight);
        gl.enable(gl.SCISSOR_TEST);
      //!!!!!note: 012!!!xyznot work!!!!I hate it
       for (var i = 0; i < R.lights.length; i++) {//R.lights.length
          if(cfg.AABBtest){
               var sc = getAABBForLight(state.viewMat, state.projMat, R.lights[i]);
             }
           else sc = getScissorForLight(state.viewMat, state.projMat, R.lights[i]);
         
           if(sc!=null){
               gl.scissor(sc[0], sc[1], sc[2], sc[3]);
               if(!cfg.debugScissor){              
                    gl.uniform3f(R.prog_BlinnPhong_PointLight.u_lightPos, R.lights[i].pos[0],R.lights[i].pos[1],R.lights[i].pos[2]);
                    gl.uniform3f(R.prog_BlinnPhong_PointLight.u_lightCol, R.lights[i].col[0],R.lights[i].col[1],R.lights[i].col[2]);
                    gl.uniform1f(R.prog_BlinnPhong_PointLight.u_lightRad, R.lights[i].rad);
                    gl.uniform3f(R.prog_BlinnPhong_PointLight.u_cameraPos, state.cameraPos.x,state.cameraPos.y,state.cameraPos.z);
                    if(cfg.toon)
                    {
                         gl.uniform1i(R.prog_BlinnPhong_PointLight.u_toon, 1);
                    }
                    else 
                    {
                         gl.uniform1i(R.prog_BlinnPhong_PointLight.u_toon, -1);
                     } 

                    renderFullScreenQuad(R.prog_BlinnPhong_PointLight);
                  }
               else 
                  {
              //additive blend 
               gl.blendFunc(gl.SRC_ALPHA, gl.DST_ALPHA); 
               renderFullScreenQuad(R.progRed);  
                }
             }          
      }
        // Disable blending so that it doesn't affect other code
        gl.disable(gl.SCISSOR_TEST);
       // gl.disable(gl.BLEND);
        if(cfg.toon)
        {
             gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);

             gl.useProgram(R.prog_toon.prog);
             gl.activeTexture(gl.TEXTURE0);
             gl.bindTexture(gl.TEXTURE_2D, R.pass_copy.depthTex);
             gl.uniform1i(R.prog_toon.u_depth, 0);
             
             gl.activeTexture(gl.TEXTURE1);
             gl.bindTexture(gl.TEXTURE_2D, R.pass_deferred.colorTex);
             gl.uniform1i(R.prog_toon.u_color, 0);
           
            renderFullScreenQuad(R.prog_toon);
        }
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
    //bloom reference: http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
    
    R.pass_bloom_w.render=function(state)
    {
    	 gl.bindFramebuffer(gl.FRAMEBUFFER,  R.pass_bloom_w.fbo );
    	 gl.clearDepth(1.0);
         gl.clear(gl.DEPTH_BUFFER_BIT);
         gl.useProgram(R.prog_bloom_w.prog);
         gl.activeTexture(gl.TEXTURE0);
        
         gl.bindTexture(gl.TEXTURE_2D, R.pass_deferred.colorTex);
        //    }
         gl.uniform1i(R.prog_bloom_w.u_color, 0);
        
        renderFullScreenQuad(R.prog_bloom_w);
    };
  R.pass_bloom_h.render=function(state)
    {
    	 gl.bindFramebuffer(gl.FRAMEBUFFER, null );
    	 gl.clearDepth(1.0);
         gl.clear(gl.DEPTH_BUFFER_BIT);

         gl.useProgram(R.prog_bloom_h.prog);
         gl.activeTexture(gl.TEXTURE0);
         gl.bindTexture(gl.TEXTURE_2D, R.pass_deferred.colorTex);
         gl.uniform1i(R.prog_bloom_h.u_color, 0);
         renderFullScreenQuad(R.prog_bloom_h);
      
    };
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
        var positions = new Float32Array([
            -1.0, -1.0, 0.0,
             1.0, -1.0, 0.0,
            -1.0,  1.0, 0.0,
             1.0,  1.0, 0.0
    
        ]);

        var vbo = null;

        var init = function() {
            vbo=gl.createBuffer();
            gl.bindBuffer(gl.ARRAY_BUFFER,vbo);
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

            gl.bindBuffer(gl.ARRAY_BUFFER,vbo);
            gl.enableVertexAttribArray(prog.a_position);
            // Use gl.vertexAttribPointer to tell WebGL the type/layout of the buffer
            gl.vertexAttribPointer(prog.a_position, 3, gl.FLOAT, false, 0, 0);
            gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

            // Unbind the array buffer.
            gl.bindBuffer(gl.ARRAY_BUFFER, null);
        };
    })();

})();
