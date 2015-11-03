(function() {
    'use strict';

    window.R = {};
    R.pass_copy = {};
    R.pass_debug = {};
    R.pass_deferred = {};
    R.pass_post1 = {};
    R.pass_toonShade = {};
    R.pass_mBlur = {};
    R.pass_scissor = {};
    R.pass_bloomGaussian_x = {};
    R.pass_bloomGaussian_y = {};
    R.lights = [];

    R.NUM_GBUFFERS = 3;

    /**
     * Set up the deferred pipeline framebuffer objects and textures.
     */
    R.deferredSetup = function() {
        setupLights();
        loadAllShaderPrograms();
        R.pass_copy.setup();
        R.pass_deferred.setup();
        R.pass_toonShade.setup();
        R.pass_mBlur.setup();
        R.pass_bloomGaussian_x.setup();
        R.pass_bloomGaussian_y.setup();
        
    };

    // TODO: Edit if you want to change the light initial positions
    R.light_min = [-14, 0, -6];
    R.light_max = [14, 18, 6];
    R.light_dt = -0.03;
    R.LIGHT_RADIUS = 4.0;
    R.NUM_LIGHTS = 8; // TODO: test with MORE lights!
    var setupLights = function() {
        Math.seedrandom(0);

        var posfn = function() {
            var r = [0, 0, 0];
            for (var i = 0; i < 3; i++) {
                var mn = R.light_min[i];
                var mx = R.light_max[i];
                r[i] = Math.random() * (mx - mn) + mn;
            }
            return r;
        };

        for (var i = 0; i < R.NUM_LIGHTS; i++) {
            R.lights.push({
                pos: posfn(),
                col: [
                    1 + Math.random(),
                    1 + Math.random(),
                    1 + Math.random()],
                rad: R.LIGHT_RADIUS
            });
        }
    };

    /**
     * Create/configure framebuffer between "copy" and "deferred" stages
     */
    R.pass_copy.setup = function() {
        // * Create the FBO
        R.pass_copy.fbo = gl.createFramebuffer();
        // * Create, bind, and store a depth target texture for the FBO
        R.pass_copy.depthTex = createAndBindDepthTargetTexture(R.pass_copy.fbo);

        // * Create, bind, and store "color" target textures for the FBO
        R.pass_copy.gbufs = [];
        var attachments = [];
        for (var i = 0; i < R.NUM_GBUFFERS; i++) {
            var attachment = gl_draw_buffers['COLOR_ATTACHMENT' + i + '_WEBGL'];
            var tex = createAndBindColorTargetTexture(R.pass_copy.fbo, attachment);
            R.pass_copy.gbufs.push(tex);
            attachments.push(attachment);
        }

        // * Check for framebuffer errors
        abortIfFramebufferIncomplete(R.pass_copy.fbo);
        // * Tell the WEBGL_draw_buffers extension which FBO attachments are
        //   being used. (This extension allows for multiple render targets.)
        gl_draw_buffers.drawBuffersWEBGL(attachments);

        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    };

    /**
     * Create/configure framebuffer between "deferred" and "post1" stages
     */
    R.pass_deferred.setup = function() {
        // * Create the FBO
        R.pass_deferred.fbo = gl.createFramebuffer();
        // * Create, bind, and store a single color target texture for the FBO
        R.pass_deferred.colorTex = createAndBindColorTargetTexture(
            R.pass_deferred.fbo, gl_draw_buffers.COLOR_ATTACHMENT0_WEBGL);

        // * Check for framebuffer errors
        abortIfFramebufferIncomplete(R.pass_deferred.fbo);
        // * Tell the WEBGL_draw_buffers extension which FBO attachments are
        //   being used. (This extension allows for multiple render targets.)
        gl_draw_buffers.drawBuffersWEBGL([gl_draw_buffers.COLOR_ATTACHMENT0_WEBGL]);

        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    };
    
    R.pass_toonShade.setup = function() {
        // * Create the FBO
        R.pass_toonShade.fbo = gl.createFramebuffer();
        // * Create, bind, and store a single color target texture for the FBO
        R.pass_toonShade.colorTex = createAndBindColorTargetTexture(
            R.pass_toonShade.fbo, gl_draw_buffers.COLOR_ATTACHMENT0_WEBGL);

        // * Check for framebuffer errors
        abortIfFramebufferIncomplete(R.pass_toonShade.fbo);
        // * Tell the WEBGL_draw_buffers extension which FBO attachments are
        //   being used. (This extension allows for multiple render targets.)
        gl_draw_buffers.drawBuffersWEBGL([gl_draw_buffers.COLOR_ATTACHMENT0_WEBGL]);

        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    };
    
    R.pass_mBlur.setup = function() {
        // * Create the FBO
        R.pass_mBlur.fbo = gl.createFramebuffer();
        // * Create, bind, and store a single color target texture for the FBO
        R.pass_mBlur.colorTex = createAndBindColorTargetTexture(
            R.pass_mBlur.fbo, gl_draw_buffers.COLOR_ATTACHMENT0_WEBGL);

        // * Check for framebuffer errors
        abortIfFramebufferIncomplete(R.pass_mBlur.fbo);
        // * Tell the WEBGL_draw_buffers extension which FBO attachments are
        //   being used. (This extension allows for multiple render targets.)
        gl_draw_buffers.drawBuffersWEBGL([gl_draw_buffers.COLOR_ATTACHMENT0_WEBGL]);

        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    };
    
    
    R.pass_bloomGaussian_x.setup = function() {
        // * Create the FBO
        R.pass_bloomGaussian_x.fbo = gl.createFramebuffer();
        // * Create, bind, and store a single color target texture for the FBO
        R.pass_bloomGaussian_x.colorTex = createAndBindColorTargetTexture(
            R.pass_bloomGaussian_x.fbo, gl_draw_buffers.COLOR_ATTACHMENT0_WEBGL);

        // * Check for framebuffer errors
        abortIfFramebufferIncomplete(R.pass_bloomGaussian_x.fbo);
        // * Tell the WEBGL_draw_buffers extension which FBO attachments are
        //   being used. (This extension allows for multiple render targets.)
        gl_draw_buffers.drawBuffersWEBGL([gl_draw_buffers.COLOR_ATTACHMENT0_WEBGL]);

        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    };

    R.pass_bloomGaussian_y.setup = function() {
        // * Create the FBO
        R.pass_bloomGaussian_y.fbo = gl.createFramebuffer();
        // * Create, bind, and store a single color target texture for the FBO
        R.pass_bloomGaussian_y.colorTex = createAndBindColorTargetTexture(
            R.pass_bloomGaussian_y.fbo, gl_draw_buffers.COLOR_ATTACHMENT0_WEBGL);

        // * Check for framebuffer errors
        abortIfFramebufferIncomplete(R.pass_bloomGaussian_y.fbo);
        // * Tell the WEBGL_draw_buffers extension which FBO attachments are
        //   being used. (This extension allows for multiple render targets.)
        gl_draw_buffers.drawBuffersWEBGL([gl_draw_buffers.COLOR_ATTACHMENT0_WEBGL]);

        gl.bindFramebuffer(gl.FRAMEBUFFER, null);
    };

    /**
     * Loads all of the shader programs used in the pipeline.
     */
    var loadAllShaderPrograms = function() {
        loadShaderProgram(gl, 'glsl/copy.vert.glsl', 'glsl/copy.frag.glsl',
            function(prog) {
                // Create an object to hold info about this shader program
                var p = { prog: prog };

                // Retrieve the uniform and attribute locations
                p.u_cameraMat = gl.getUniformLocation(prog, 'u_cameraMat');
                p.u_colmap    = gl.getUniformLocation(prog, 'u_colmap');
                p.u_normap    = gl.getUniformLocation(prog, 'u_normap');
                p.a_position  = gl.getAttribLocation(prog, 'a_position');
                p.a_normal    = gl.getAttribLocation(prog, 'a_normal');
                p.a_uv        = gl.getAttribLocation(prog, 'a_uv');
                p.u_specularExp = gl.getUniformLocation(prog, 'u_specularExp');
                p.u_specularCoeff = gl.getUniformLocation(prog, 'u_specularCoeff');

                // Save the object into this variable for access later
                R.progCopy = p;
            });

        loadShaderProgram(gl, 'glsl/quad.vert.glsl', 'glsl/red.frag.glsl',
            function(prog) {
                // Create an object to hold info about this shader program
                R.progRed = { prog: prog };
            });

        loadShaderProgram(gl, 'glsl/quad.vert.glsl', 'glsl/clear.frag.glsl',
            function(prog) {
                // Create an object to hold info about this shader program
                R.progClear = { prog: prog };
            });

        loadDeferredProgram('ambient', function(p) {
            // Save the object into this variable for access later
            R.prog_Ambient = p;
        });

        loadDeferredProgram('red', function(p) {
            // Save the object into this variable for access later
            R.prog_scissor = p;
        });
        
        loadDeferredProgram('blinnphong-pointlight', function(p) {
            // Save the object into this variable for access later
            p.u_lightPos = gl.getUniformLocation(p.prog, 'u_lightPos');
            p.u_lightCol = gl.getUniformLocation(p.prog, 'u_lightCol');
            p.u_lightRad = gl.getUniformLocation(p.prog, 'u_lightRad');
            p.u_viewPos = gl.getUniformLocation(p.prog, 'u_viewPos');
            R.prog_BlinnPhong_PointLight = p;
        });

        loadDeferredProgram('tilebased-light', function(p) {
            // Save the object into this variable for access later
            p.u_lightPos = gl.getUniformLocation(p.prog, 'u_lightPos');
            p.u_lightCol = gl.getUniformLocation(p.prog, 'u_lightCol');
            p.u_lightList = gl.getUniformLocation(p.prog, 'u_lightList');
            p.u_lightTextureWidth = gl.getUniformLocation(p.prog, 'u_lightTextureWidth');
            p.u_lightOffsetX = gl.getUniformLocation(p.prog, 'u_lightOffsetX');
            p.u_lightOffsetY = gl.getUniformLocation(p.prog, 'u_lightOffsetY');
            p.u_totalLight = gl.getUniformLocation(p.prog, 'u_totalLight');
            p.u_viewPos = gl.getUniformLocation(p.prog, 'u_viewPos');
            R.prog_tilebased_light = p;
            
            //setup for tile-based render
            p.tileSize = 40.0;
            p.tx = Math.ceil(width / p.tileSize);
            p.ty = Math.ceil(height / p.tileSize);
            p.total = p.tx * p.ty;
            p.viewPos = new Float32Array(3);
            p.lightPos = new Float32Array(R.lights.length * 3);
            p.lightCol = new Float32Array(R.lights.length * 4);
            p.lightOffset = new Float32Array(p.total);
            p.lightNo = new Float32Array(p.total);
            for (var i = 0; i < R.lights.length; i++) {
                var light = R.lights[i];
                        
                p.lightCol[i*4] = light.col[0];
                p.lightCol[i*4 + 1] = light.col[1];
                p.lightCol[i*4 + 2] = light.col[2];
                p.lightCol[i*4 + 3] = light.rad;
                
            }
            
            p.lightColTexture = gl.createTexture();
            gl.activeTexture(gl.TEXTURE0);
            gl.bindTexture(gl.TEXTURE_2D, p.lightColTexture);
            gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, R.lights.length, 1, 0, gl.RGBA, gl.FLOAT, p.lightCol);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
            
            p.lightPosTexture = gl.createTexture();
            gl.activeTexture(gl.TEXTURE0);
            gl.bindTexture(gl.TEXTURE_2D, p.lightPosTexture);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
            
            p.lightListTexture = gl.createTexture();
            gl.activeTexture(gl.TEXTURE0);
            gl.bindTexture(gl.TEXTURE_2D, p.lightListTexture);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
            gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
            
        });

        loadDeferredProgram('debug', function(p) {
            p.u_debug = gl.getUniformLocation(p.prog, 'u_debug');
            // Save the object into this variable for access later
            R.prog_Debug = p;
        });

        loadPostProgram('one', function(p) {
            p.u_color    = gl.getUniformLocation(p.prog, 'u_color');
            // Save the object into this variable for access later
            R.progPost1 = p;
        });
        
        loadPostProgram('gblur_x', function(p) {
            p.u_color    = gl.getUniformLocation(p.prog, 'u_color');
            p.u_width    = gl.getUniformLocation(p.prog, 'u_width');
            // Save the object into this variable for access later
            R.prog_bloomGaussian_x = p;
        });
        
        loadPostProgram('gblur_y', function(p) {
            p.u_color    = gl.getUniformLocation(p.prog, 'u_color');
            p.u_height    = gl.getUniformLocation(p.prog, 'u_height');
            // Save the object into this variable for access later
            R.prog_bloomGaussian_y = p;
        });

        loadPostProgram('toon', function(p) {
            p.u_color    = gl.getUniformLocation(p.prog, 'u_color');
            p.u_depth    = gl.getUniformLocation(p.prog, 'u_depth');
            p.u_width    = gl.getUniformLocation(p.prog, 'u_width');
            p.u_height   = gl.getUniformLocation(p.prog, 'u_height');
            // Save the object into this variable for access later
            R.prog_toonShade = p;
        });
        
        loadPostProgram('mblur', function(p) {
            p.u_color    = gl.getUniformLocation(p.prog, 'u_color');
            p.u_depth    = gl.getUniformLocation(p.prog, 'u_depth');
            p.u_inverseVProj   = gl.getUniformLocation(p.prog, 'u_inverseVProj');
            p.u_previousVProj   = gl.getUniformLocation(p.prog, 'u_previousVProj');
            // Save the object into this variable for access later
            R.prog_mBlur = p;
        });
    };

    var loadDeferredProgram = function(name, callback) {
        loadShaderProgram(gl, 'glsl/quad.vert.glsl',
                          'glsl/deferred/' + name + '.frag.glsl',
            function(prog) {
                // Create an object to hold info about this shader program
                var p = { prog: prog };

                // Retrieve the uniform and attribute locations
                p.u_gbufs = [];
                for (var i = 0; i < R.NUM_GBUFFERS; i++) {
                    p.u_gbufs[i] = gl.getUniformLocation(prog, 'u_gbufs[' + i + ']');
                }
                p.u_depth    = gl.getUniformLocation(prog, 'u_depth');
                p.a_position = gl.getAttribLocation(prog, 'a_position');

                callback(p);
            });
    };

    var loadPostProgram = function(name, callback) {
        loadShaderProgram(gl, 'glsl/quad.vert.glsl',
                          'glsl/post/' + name + '.frag.glsl',
            function(prog) {
                // Create an object to hold info about this shader program
                var p = { prog: prog };

                // Retrieve the uniform and attribute locations
                p.a_position = gl.getAttribLocation(prog, 'a_position');

                callback(p);
            });
    };

    var createAndBindDepthTargetTexture = function(fbo) {
        var depthTex = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, depthTex);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texImage2D(
            gl.TEXTURE_2D, 0, gl.DEPTH_COMPONENT, width, height, 0,
            gl.DEPTH_COMPONENT, gl.UNSIGNED_SHORT, null);
        gl.bindTexture(gl.TEXTURE_2D, null);

        gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
        gl.framebufferTexture2D(
            gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.TEXTURE_2D, depthTex, 0);

        return depthTex;
    };

    var createAndBindColorTargetTexture = function(fbo, attachment) {
        var tex = gl.createTexture();
        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.FLOAT, null);
        gl.bindTexture(gl.TEXTURE_2D, null);

        gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
        gl.framebufferTexture2D(gl.FRAMEBUFFER, attachment, gl.TEXTURE_2D, tex, 0);

        return tex;
    };
})();
