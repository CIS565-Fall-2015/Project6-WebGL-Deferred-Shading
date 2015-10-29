window.aborted = false;
window.abort = function(s) {
    'use strict';
    var m = 'Fatal error: ' + s;
    if (!aborted) {
        $('#alertcontainer').css('display', 'block');
        aborted = true;
        $('#alerttext').text(m);
    }
    console.log(m);
    throw m;
};

window.loadTexture = (function() {
    'use strict';

    var handleTextureLoaded = function(img, tex) {
        gl.bindTexture(gl.TEXTURE_2D, tex);
        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, img);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT);
        gl.generateMipmap(gl.TEXTURE_2D);
        gl.bindTexture(gl.TEXTURE_2D, null);
    };

    return function(url) {
        return new Promise(function(resolve){
            var prom = Promise.resolve();

            var tex = gl.createTexture();
            var img = new Image();
            img.onload = function() {
                handleTextureLoaded(img, tex);
                resolve(tex);
            };
            img.src = url;
        });
    };
})();

window.loadShaderProgram = (function() {
    'use strict';

    var compileShader = function(gl, shaderSource, shaderType) {
        var shader = gl.createShader(shaderType);
        gl.shaderSource(shader, shaderSource);
        gl.compileShader(shader);
        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
            console.error(shaderSource);
            abort('shader compiler error:\n' + gl.getShaderInfoLog(shader));
        }

        return shader;
    };

    var linkShader = function(gl, vs, fs) {
        var prog = gl.createProgram();
        gl.attachShader(prog, vs);
        gl.attachShader(prog, fs);
        gl.linkProgram(prog);
        if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) {
            abort('shader linker error:\n' + gl.getProgramInfoLog(prog));
        }
        return prog;
    };

    return function(gl, urlVS, urlFS, callback) {
        return Promise.all([$.get(urlVS), $.get(urlFS)]).then(
            function(results) {
                var vs = results[0], fs = results[1];
                vs = compileShader(gl, vs, gl.VERTEX_SHADER);
                fs = compileShader(gl, fs, gl.FRAGMENT_SHADER);
                return linkShader(gl, vs, fs);
            }).then(callback).catch(abort);
    };
})();

window.loadModel = function(obj, callback) {
    'use strict';

    var onProgress = function(xhr) {
        if (xhr.lengthComputable) {
            var percentComplete = xhr.loaded / xhr.total * 100;
            var msg = obj + ': ' + Math.round(percentComplete, 2) + '% loaded';
            console.log(msg);
            $('#msgbox').text(msg);
        }
    };

    var onError = function(xhr) {
        console.log("Failed to load model");
    };

    var loader = new THREE.OBJLoader();
    loader.load(obj, callback, onProgress, onError);
};

window.readyModelForDraw = function(prog, m) {
    gl.useProgram(prog.prog);

    if (m.colmap) {
        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, m.colmap);
        gl.uniform1i(prog.u_colmap, 0);
    }
    if (m.normap) {
        gl.activeTexture(gl.TEXTURE1);
        gl.bindTexture(gl.TEXTURE_2D, m.normap);
        gl.uniform1i(prog.u_normap, 1);
    }
    if (m.material !== undefined) {
        gl.uniform1f(prog.u_material, m.material);
    }

    gl.enableVertexAttribArray(prog.a_position);
    gl.bindBuffer(gl.ARRAY_BUFFER, m.position);
    gl.vertexAttribPointer(prog.a_position, 3, gl.FLOAT, false, 0, 0);

    if (prog.a_normal !== -1 && m.normal) {
        gl.enableVertexAttribArray(prog.a_normal);
        gl.bindBuffer(gl.ARRAY_BUFFER, m.normal);
        gl.vertexAttribPointer(prog.a_normal, 3, gl.FLOAT, false, 0, 0);
    }
    if (prog.a_uv !== -1 && m.uv) {
        gl.enableVertexAttribArray(prog.a_uv);
        gl.bindBuffer(gl.ARRAY_BUFFER, m.uv);
        gl.vertexAttribPointer(prog.a_uv, 2, gl.FLOAT, false, 0, 0);
    }

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, m.idx);
};

window.drawReadyModel = function(m) {
    gl.drawElements(gl.TRIANGLES, m.elemCount, gl.UNSIGNED_INT, 0);
};

window.getScissorForLight = (function() {
    // Pre-allocate for performance - avoids additional allocation
    var a = new THREE.Vector4(0, 0, 0, 0);
    var b = new THREE.Vector4(0, 0, 0, 0);
    var minpt = new THREE.Vector2(0, 0);
    var maxpt = new THREE.Vector2(0, 0);
    var ret = [0, 0, 0, 0];

    return function(view, proj, l) {
        // front bottom-left corner of sphere's bounding cube
        a.fromArray(l.pos);
        a.w = 1;
        a.applyMatrix4(view);
        a.x -= l.rad;
        a.y -= l.rad;
        a.z += l.rad;
        a.applyMatrix4(proj);
        a.divideScalar(a.w);

        // front bottom-left corner of sphere's bounding cube
        b.fromArray(l.pos);
        b.w = 1;
        b.applyMatrix4(view);
        b.x += l.rad;
        b.y += l.rad;
        b.z += l.rad;
        b.applyMatrix4(proj);
        b.divideScalar(b.w);

        minpt.set(Math.max(-1, a.x), Math.max(-1, a.y));
        maxpt.set(Math.min( 1, b.x), Math.min( 1, b.y));

        if (maxpt.x < -1 || 1 < minpt.x ||
            maxpt.y < -1 || 1 < minpt.y) {
            return null;
        }

        minpt.addScalar(1.0); minpt.multiplyScalar(0.5);
        maxpt.addScalar(1.0); maxpt.multiplyScalar(0.5);

        ret[0] = Math.round(width * minpt.x);
        ret[1] = Math.round(height * minpt.y);
        ret[2] = Math.round(width * (maxpt.x - minpt.x));
        ret[3] = Math.round(height * (maxpt.y - minpt.y));
        return ret;
    };
})();

window.getImprovedScissorForLight = (function() {
    // Pre-allocate for performance - avoids additional allocation
    var a = new THREE.Vector4(0, 0, 0, 0);
    var b = new THREE.Vector4(0, 0, 0, 0);
    var c = new THREE.Vector4(0, 0, 0, 0);
    var d = new THREE.Vector4(0, 0, 0, 0);
    var minpt = new THREE.Vector2(0, 0);
    var minpt2 = new THREE.Vector2(0, 0);
    var maxpt = new THREE.Vector2(0, 0);
    var maxpt2 = new THREE.Vector2(0, 0);
    var ret = [0, 0, 0, 0];

    return function(view, proj, l) {
        // front bottom-left corner of sphere's bounding cube
        a.fromArray(l.pos);
        a.w = 1;
        a.applyMatrix4(view);
        a.x -= l.rad;
        a.y -= l.rad;
        a.z -= l.rad;
        a.applyMatrix4(proj);
        a.divideScalar(a.w);

        // front upper-right corner of sphere's bounding cube
        b.fromArray(l.pos);
        b.w = 1;
        b.applyMatrix4(view);
        b.x += l.rad;
        b.y += l.rad;
        b.z += l.rad;
        b.applyMatrix4(proj);
        b.divideScalar(b.w);

        //back bottom-left corner of sphere's bounding cube
        /*c.fromArray(l.pos);
        c.w = 1;
        c.x -= l.rad;
        c.y -= l.rad;
        c.z -= l.rad;
        c.applyMatrix4(proj);
        c.divideScalar(c.w);

        //back upper-right corner of sphere's bounding cube
        d.fromArray(l.pos);
        d.w = 1;
        d.applyMatrix4(view);
        d.x += l.rad;
        d.y += l.rad;
        d.z -= l.rad;
        d.applyMatrix4(proj);
        d.divideScalar(d.w);*/

        minpt.set(Math.max(-1, a.x), Math.max(-1, a.y));
        //minpt2.set(Math.max(-1, c.x), Math.max(-1, c.y));
        maxpt.set(Math.min( 1, b.x), Math.min( 1, b.y));
        //maxpt2.set(Math.min(1, d.x), Math.min(1, d.y));

        //minpt.set(Math.min(a.x, c.x), Math.min(a.y, c.y));
        //maxpt.set(Math.max(b.x, d.x), Math.max(b.y, d.y));

        if (maxpt.x < -1 || 1 < minpt.x ||
            maxpt.y < -1 || 1 < minpt.y) {
            return null;
        }

        minpt.addScalar(1.0); minpt.multiplyScalar(0.5);
        maxpt.addScalar(1.0); maxpt.multiplyScalar(0.5);

        ret[0] = Math.round(width * minpt.x);
        ret[1] = Math.round(height * minpt.y);
        ret[2] = Math.round(width * (maxpt.x - minpt.x));
        ret[3] = Math.round(height * (maxpt.y - minpt.y));
        return ret;
    };
})();

window.abortIfFramebufferIncomplete = function(fbo) {
    gl.bindFramebuffer(gl.FRAMEBUFFER, fbo);
    var fbstatus = gl.checkFramebufferStatus(gl.FRAMEBUFFER);
    if (fbstatus !== gl.FRAMEBUFFER_COMPLETE) {
        abort('framebuffer incomplete: ' + WebGLDebugUtils.glEnumToString(fbstatus));
    }
};

window.downloadCanvas = (function() {
    var downloadURI = function(uri, name) {
        var link = document.createElement('a');
        link.download = name;
        link.href = uri;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
    };

    return function() {
        var canvas = document.getElementById('canvas');
        var time = Date.now();
        var img = canvas.toDataURL('image/png');
        downloadURI(img, 'deferred-' + time + '.png');
    };
})();
