var cfg;

(function() {
    'use strict';

    var Cfg = function() {
        this.debugView = -1;
        this.debugScissor = false;

        this.optimization = 1;
        this.movingLights = true;
        this.toon = false;
        this.watercolor = false;

        this.ambient = 0.1;
        this.lightRadius = 4.0;
        this.numLights = 50;

        this.tileSize = 100;
        this.tileDebugView = -1;
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
        debug.open();

        var opt = gui.addFolder('Optimizations');
        opt.add(cfg, 'optimization', {
            'None':   -1,
            'Scissor': 0,
            'Tile':    1,
        });
        opt.add(cfg, 'debugScissor');
        opt.open();

        var effects = gui.addFolder('Effects');
        effects.add(cfg, 'movingLights');
        effects.add(cfg, 'toon');
        effects.add(cfg, 'watercolor');
        effects.open();

        var updateLights = function() {
            var TILE_SIZE = cfg.tileSize;
            var TILES_WIDTH  = Math.ceil((width+1)  / TILE_SIZE);
            var TILES_HEIGHT = Math.ceil((height+1) / TILE_SIZE);
            var NUM_TILES = TILES_WIDTH * TILES_HEIGHT;
            R.setupLights(cfg.numLights, cfg.lightRadius, NUM_TILES);
        };

        var consts = gui.addFolder('Constants');
        consts.add(cfg, 'ambient', 0.1, 1.0);
        consts.add(cfg, 'lightRadius', 0.5, 10.0).onFinishChange(updateLights);
        consts.add(cfg, 'numLights').min(5).max(500).step(5).onFinishChange(updateLights);
        //consts.add(cfg, 'numLights').min(50).max(100).step(10).onFinishChange(updateLights);

        consts.open();

        var tileOpts = gui.addFolder('Tile Options');
        tileOpts.add(cfg, 'tileSize').min(10).max(150).step(25);
        tileOpts.add(cfg, 'tileDebugView', {
            'None': -1,
            '# Lights': 0
        });
        tileOpts.open();

        updateLights();
    };

    window.handle_load.push(init);
})();
