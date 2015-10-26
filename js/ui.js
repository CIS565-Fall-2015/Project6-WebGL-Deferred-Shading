var cfg;

(function() {
    'use strict';

    var Cfg = function() {
        this.debugView = -1;
        this.debugScissor = false;
        this.enableEffect0 = false;
        this.disable = false;
        this.toon = false;
    };

    var init = function() {
        cfg = new Cfg();

        var gui = new dat.GUI();
        gui.add(cfg, 'debugView', {
            'None':             -1,
            '0 Depth':           0,
            '1 Position':        1,
            '2 Geometry normal': 2,
            '3 Color map':       3,
            '4 Normal map':      4,
            '5 Surface normal':  5
        });
        gui.add(cfg, 'debugScissor');
        gui.add(cfg, 'toon');

        var eff0 = gui.addFolder('EFFECT NAME HERE');
        eff0.add(cfg, 'enableEffect0');
    };

    window.handle_load.push(init);
})();
