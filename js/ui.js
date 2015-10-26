var cfg;

(function() {
    'use strict';

    var Cfg = function() {
        this.debugView = -1;
        this.debugScissor = false;

        this.enableScissor = true;
        this.toon = false;

        this.ambient = 0.2;
        this.lightRadius = 4.0;
        this.numLights = 25;
    };

    var init = function() {
        cfg = new Cfg();

        var gui = new dat.GUI();
        var debug = gui.addFolder('Debug Views');
        debug.add(cfg, 'debugView', {
            'None':             -1,
            '0 Depth':           0,
            '1 Position':        1,
            '2 Geometry normal': 2,
            '3 Color map':       3,
            '4 Normal map':      4,
            '5 Surface normal':  5
        });
        debug.add(cfg, 'debugScissor');
        debug.open();

        var modes = gui.addFolder('Modes');
        modes.add(cfg, 'enableScissor');
        modes.add(cfg, 'toon');
        modes.open();

        var consts = gui.addFolder('Constants');
        consts.add(cfg, 'ambient', 0.1, 1.0);
        consts.add(cfg, 'lightRadius', 0.5, 10.0);
        consts.add(cfg, 'numLights', 1, 1000);
        consts.open();
    };

    window.handle_load.push(init);
})();
