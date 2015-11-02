(function() {
    'use strict';

    window.R = {};
    R.pass_copy = {};
    R.pass_debug = {};
    R.pass_deferred = {};
    R.pass_toon = {};
    R.pass_post1 = {};
    R.pass_post1_compressed = {};
    R.lights = [];

    R.NUM_GBUFFERS = 4;

    // workflow using compressed g buffers
    R.pass_copy_compressed = {};
    R.pass_debug_compressed = {};
    R.pass_deferred_compressed = {};

    // workflow using tiling
    R.pass_copy_tile = {};
    R.pass_debug_tile = {};

    R.NUM_GBUFFERS_COMPRESSED = 2;

    /**
     * Set up the deferred pipeline framebuffer objects and textures.
     */
    R.deferredSetup = function() {
        setupLights();
        loadAllShaderPrograms(); // load all the shader programs and get attribute/uniform positions
        R.pass_copy.setup(); // allocate
        R.pass_deferred.setup(); // allocate

        // compressed g-buffers
        R.pass_copy_compressed.setup(); // allocate
        R.pass_deferred_compressed.setup();

        // tiling
        R.pass_copy_tile.setup();

        console.log("setup complete");
    };

    // TODO: Edit if you want to change the light initial positions
    R.light_min = [-14, 0, -6];
    R.light_max = [14, 18, 6];
    R.light_dt = -0.03;
    R.LIGHT_RADIUS = 4.0;
    R.NUM_LIGHTS = 20; // TODO: test with MORE lights!
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

    R.pass_copy_tile.setup = function() {
        // * Create the FBO
        R.pass_copy_tile.fbo = gl.createFramebuffer();
        // * Create, bind, and store a depth target texture for the FBO
        R.pass_copy_tile.depthTex = createAndBindDepthTargetTexture(R.pass_copy_tile.fbo);

        // * Create, bind, and store "color" target textures for the FBO
        // these are the g buffers
        // also need a gbuf for lights themselves and a gbuf for tile light lists        
        R.pass_copy_tile.gbufs = [];
        var attachments = [];
        for (var i = 0; i < R.NUM_GBUFFERS + 2; i++) {
            var attachment = gl_draw_buffers['COLOR_ATTACHMENT' + i + '_WEBGL'];
            var tex = createAndBindColorTargetTexture(R.pass_copy_tile.fbo, attachment);
            R.pass_copy_tile.gbufs.push(tex);
            attachments.push(attachment);
        }

        // * Check for framebuffer errors
        abortIfFramebufferIncomplete(R.pass_copy_tile.fbo);
        // * Tell the WEBGL_draw_buffers extension which FBO attachments are
        //   being used. (This extension allows for multiple render targets.)
        gl_draw_buffers.drawBuffersWEBGL(attachments);
    }

    /**
     * Create/configure framebuffer between "copy" and "deferred" stages
     */
    R.pass_copy.setup = function() {
        // * Create the FBO
        R.pass_copy.fbo = gl.createFramebuffer();
        // * Create, bind, and store a depth target texture for the FBO
        R.pass_copy.depthTex = createAndBindDepthTargetTexture(R.pass_copy.fbo);

        // * Create, bind, and store "color" target textures for the FBO
        // these are the g buffers
        R.pass_copy.gbufs = [];
        var attachments = [];
        for (var i = 0; i < R.NUM_GBUFFERS; i++) {
            var attachment = gl_draw_buffers['COLOR_ATTACHMENT' + i + '_WEBGL'];
            var tex = createAndBindColorTargetTexture(R.pass_copy.fbo, attachment);
            R.pass_copy.gbufs.push(tex);
            attachments.push(attachment);
        }

        // this basically attaches a bunch of draw_buffers to the fbo?

        // * Check for framebuffer errors
        abortIfFramebufferIncomplete(R.pass_copy.fbo);
        // * Tell the WEBGL_draw_buffers extension which FBO attachments are
        //   being used. (This extension allows for multiple render targets.)
        gl_draw_buffers.drawBuffersWEBGL(attachments);
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
    };

    /**
     * Create/configure framebuffer between "deferred" and "post1" stages
     */
    R.pass_deferred_compressed.setup = function() {
        // * Create the FBO
        R.pass_deferred_compressed.fbo = gl.createFramebuffer();
        // * Create, bind, and store a single color target texture for the FBO
        R.pass_deferred_compressed.colorTex = createAndBindColorTargetTexture(
            R.pass_deferred_compressed.fbo, gl_draw_buffers.COLOR_ATTACHMENT0_WEBGL);

        // * Check for framebuffer errors
        abortIfFramebufferIncomplete(R.pass_deferred_compressed.fbo);
        // * Tell the WEBGL_draw_buffers extension which FBO attachments are
        //   being used. (This extension allows for multiple render targets.)
        gl_draw_buffers.drawBuffersWEBGL([gl_draw_buffers.COLOR_ATTACHMENT0_WEBGL]);
    };

    /**
     * Create/configure framebuffer between "copy" and "deferred" stages for compressed workflow
     */
    R.pass_copy_compressed.setup = function() {
        // * Create the FBO
        R.pass_copy_compressed.fbo = gl.createFramebuffer();
        // * Create, bind, and store a depth target texture for the FBO
        R.pass_copy_compressed.depthTex = createAndBindDepthTargetTexture(R.pass_copy_compressed.fbo);

        // * Create, bind, and store "color" target textures for the FBO
        // these are the g buffers
        R.pass_copy_compressed.gbufs = [];
        var attachments = [];
        for (var i = 0; i < R.NUM_GBUFFERS_COMPRESSED; i++) {
            // don't want to use the same draw buffers over again?
            var attachment = gl_draw_buffers['COLOR_ATTACHMENT' + i + '_WEBGL'];
            var tex = createAndBindColorTargetTexture(R.pass_copy_compressed.fbo, attachment);
            console.log(attachment);

            R.pass_copy_compressed.gbufs.push(tex);
            attachments.push(attachment);
        }

        // this basically attaches a bunch of draw_buffers to the fbo?

        // * Check for framebuffer errors
        abortIfFramebufferIncomplete(R.pass_copy_compressed.fbo);
        // * Tell the WEBGL_draw_buffers extension which FBO attachments are
        //   being used. (This extension allows for multiple render targets.)
        gl_draw_buffers.drawBuffersWEBGL(attachments);
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

        loadDeferredProgram('ambientToon', function(p) {
            // Save the object into this variable for access later
            R.prog_ToonAmbient = p;
        });        

        loadDeferredProgram('blinnphong-pointlight', function(p) {
            // Save the object into this variable for access later
            p.u_camPos = gl.getUniformLocation(p.prog, 'u_camPos');            
            p.u_lightPos = gl.getUniformLocation(p.prog, 'u_lightPos');
            p.u_lightCol = gl.getUniformLocation(p.prog, 'u_lightCol');
            p.u_lightRad = gl.getUniformLocation(p.prog, 'u_lightRad');
            R.prog_BlinnPhong_PointLight = p;
        });

        loadDeferredProgram('toon', function(p) {
            // Save the object into this variable for access later
            p.u_camPos = gl.getUniformLocation(p.prog, 'u_camPos');            
            p.u_lightPos = gl.getUniformLocation(p.prog, 'u_lightPos');
            p.u_lightCol = gl.getUniformLocation(p.prog, 'u_lightCol');
            p.u_lightRad = gl.getUniformLocation(p.prog, 'u_lightRad');
            R.prog_Toon = p;
        });        

        loadDeferredProgram('debug', function(p) {
            p.u_debug = gl.getUniformLocation(p.prog, 'u_debug');
            // Save the object into this variable for access later
            R.prog_Debug = p;
        });

        loadPostProgram('one', function(p) {
            p.u_color    = gl.getUniformLocation(p.prog, 'u_color');
            p.u_bloom = gl.getUniformLocation(p.prog, 'u_bloom');
            // Save the object into this variable for access later
            R.progPost1 = p;
        });

        // TODO: If you add more passes, load and set up their shader programs.
        // compressed position/normal workflow
        loadShaderProgram(gl, 'glsl/packing/copyPack.vert.glsl', 'glsl/packing/copyPack.frag.glsl',
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

                // Save the object into this variable for access later
                R.progCopyCompressed = p;
            }); 

        loadShaderProgram(gl, 'glsl/quad.vert.glsl', 'glsl/packing/debugPack.frag.glsl',
            function(prog) {
                // Create an object to hold info about this shader program
                var p = { prog: prog };

                // Retrieve the uniform and attribute locations
                p.u_gbufs = [];
                for (var i = 0; i < R.NUM_GBUFFERS_COMPRESSED; i++) {
                    p.u_gbufs[i] = gl.getUniformLocation(prog, 'u_gbufs[' + i + ']');
                }
                p.u_depth    = gl.getUniformLocation(prog, 'u_depth');
                p.a_position = gl.getAttribLocation(prog, 'a_position');
                p.u_debug = gl.getUniformLocation(p.prog, 'u_debug');
                p.u_invCameraMat = gl.getUniformLocation(prog, 'u_invCameraMat');

                R.prog_DebugCompressed = p;
            });

        loadShaderProgram(gl, 'glsl/quad.vert.glsl', 'glsl/packing/clearPack.frag.glsl',
            function(prog) {
                // Create an object to hold info about this shader program
                R.progClearCompressed = { prog: prog };
            });

        loadShaderProgram(gl, 'glsl/quad.vert.glsl',
                          'glsl/packing/blinnphong-pointlightPack.frag.glsl',
            function(prog) {
                // Create an object to hold info about this shader program
                var p = { prog: prog };

                // Retrieve the uniform and attribute locations
                p.u_gbufs = [];
                for (var i = 0; i < R.NUM_GBUFFERS_COMPRESSED; i++) {
                    p.u_gbufs[i] = gl.getUniformLocation(prog, 'u_gbufs[' + i + ']');
                }
                p.u_depth    = gl.getUniformLocation(prog, 'u_depth');

                p.u_camPos = gl.getUniformLocation(p.prog, 'u_camPos');            
                p.u_lightPos = gl.getUniformLocation(p.prog, 'u_lightPos');
                p.u_lightCol = gl.getUniformLocation(p.prog, 'u_lightCol');
                p.u_lightRad = gl.getUniformLocation(p.prog, 'u_lightRad');
                p.u_invCameraMat = gl.getUniformLocation(prog, 'u_invCameraMat');

                R.prog_BlinnPhong_PointLightCompressed = p;
            }); 

        loadShaderProgram(gl, 'glsl/quad.vert.glsl',
                          'glsl/packing/ambientPack.frag.glsl',
            function(prog) {
                // Create an object to hold info about this shader program
                var p = { prog: prog };

                // Retrieve the uniform and attribute locations
                p.u_gbufs = [];
                for (var i = 0; i < R.NUM_GBUFFERS_COMPRESSED; i++) {
                    p.u_gbufs[i] = gl.getUniformLocation(prog, 'u_gbufs[' + i + ']');
                }
                p.u_depth    = gl.getUniformLocation(prog, 'u_depth');

                R.prog_AmbientCompressed = p;
            });

        loadShaderProgram(gl, 'glsl/quad.vert.glsl',
            'glsl/tiled-numlights-debug.frag.glsl',
            function(prog) {
                // Create an object to hold info about this shader program
                var p = { prog: prog };

                // Retrieve the uniform and attribute locations
                p.u_gbufs = [];
                for (var i = 0; i < R.NUM_GBUFFERS + 2; i++) {
                    p.u_gbufs[i] = gl.getUniformLocation(prog, 'u_gbufs[' + i + ']');
                }
                p.u_depth    = gl.getUniformLocation(prog, 'u_depth');
                p.u_width = gl.getUniformLocation(p.prog, 'u_width');
                p.u_height = gl.getUniformLocation(p.prog, 'u_height');
                p.u_tileSize = gl.getUniformLocation(p.prog, 'u_tileSize');
                p.u_numLightsMax = gl.getUniformLocation(p.prog, 'u_numLightsMax');

                R.prog_DebugTiling = p;
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
