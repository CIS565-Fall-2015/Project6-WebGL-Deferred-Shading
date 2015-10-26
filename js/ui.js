var cfg;

(function() {
    'use strict';

    var Cfg = function() {
        this.debugView = -1;
        this.debugScissor = false;
        this.improvedAABB = true;
        this.effects = -1;
    };

    var init = function() {
        cfg = new Cfg();

        var gui = new dat.GUI();
        gui.add(cfg, 'debugView', {
            'None':             -1,
            '0 Depth':           0,
            '1 Position':        1,
            '2 Surface normal': 2,
            '3 Color map':       3
        });
        gui.add(cfg, 'debugScissor');
        gui.add(cfg, 'improvedAABB');
        gui.add(cfg, 'effects', {
            'None': -1,
            '0 Bloom': 0,
            '1 Toon': 1
        });
    };

    window.handle_load.push(init);
})();
