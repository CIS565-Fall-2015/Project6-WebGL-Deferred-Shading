var cfg;

(function() {
    'use strict';

    var Cfg = function() {
        // TODO: Define config fields and defaults here
        this.debugView = -1;
        this.debugScissor = false;
        this.enableScissor = false;        
        this.enableBloom = false;
        this.enableToon = false;        
        this.compressedGbuffers = false;
        this.debugTiling = false;        
        this.enableTiling = false;
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
        gui.add(cfg, 'enableScissor');
        gui.add(cfg, 'debugTiling');
        gui.add(cfg, 'enableTiling');

        var eff0 = gui.addFolder('effects');
        eff0.add(cfg, 'enableBloom');
        eff0.add(cfg, 'enableToon');        
        gui.add(cfg, 'compressedGbuffers');
    };

    window.handle_load.push(init);
})();
