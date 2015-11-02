var cfg;

(function() {
    'use strict';

    var Cfg = function() {
        this.debugView = -1;
        this.debugScissor = false;

        this.optimization = 1;
        this.toon = false;

        this.ambient = 0.2;
        this.lightRadius = 4.0;
        this.numLights = 10;
    };

    var init = function() {
        cfg = new Cfg();

        var gui = new dat.GUI();
        var debug = gui.addFolder('Debug Views');
        debug.add(cfg, 'debugView', {
            'None':               -1,
            '[0] Depth':           0,
            '[1] Position':        1,
            '[2] Geometry normal': 2,
            '[3] Color map':       3,
            '[4] Normal map':      4,
            '[5] Surface normal':  5
        });
        debug.add(cfg, 'debugScissor');
        debug.open();

        var opt = gui.addFolder('Optimizations');
        opt.add(cfg, 'optimization', {
            'None':   -1,
            'Scissor': 0,
            'Tile':    1,
        });
        opt.open();

        var effects = gui.addFolder('Effects');
        effects.add(cfg, 'toon');
        effects.open();

        var updateLights = function() {
            R.setupLights(cfg.numLights, cfg.lightRadius);
        };

        var consts = gui.addFolder('Constants');
        consts.add(cfg, 'ambient', 0.1, 1.0);
        consts.add(cfg, 'lightRadius', 0.5, 10.0).onFinishChange(updateLights);
        consts.add(cfg, 'numLights').min(5).max(500).step(5).onFinishChange(updateLights);

        consts.open();
        updateLights();
    };

    window.handle_load.push(init);
})();
