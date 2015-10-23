var cfg;

(function() {
    'use strict';

    var Cfg = function() {
        // TODO: Define config fields and defaults here
        this.debugView = -1;
        this.debugScissor = false;
        this.scissoring = true;
        this.effects = -1;
    };

    var init = function() {
        cfg = new Cfg();

        var gui = new dat.GUI();
        // TODO: Define any other possible config values
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

        gui.add(cfg, 'scissoring');
        gui.add(cfg, 'effects', {
            'None':             -1,
            '0 Bloom':           0,
            '1 Toon':        1
        });
        // TODO: add more effects toggles and parameters here
    };

    window.handle_load.push(init);
})();
