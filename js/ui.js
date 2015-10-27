var cfg;

(function() {
    'use strict';

    var Cfg = function() {
        // TODO: Define config fields and defaults here
        this.debugView = -1;
        this.enableScissor = false;
        this.debugScissor = false;
        this.enableToonShading = false;
        this.enableRampShading = false;
        this.enableBloom = false;
        this.enableSphere = false;
        this.enablePost2 = false;
        this.debugSphere = false;
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
        gui.add(cfg, 'enableScissor');
        gui.add(cfg, 'debugScissor');
        gui.add(cfg, 'debugSphere');

        var eff0 = gui.addFolder('Effects');
        eff0.add(cfg, 'enableToonShading');
        eff0.add(cfg, 'enableRampShading');
        eff0.add(cfg, 'enableBloom');
        eff0.add(cfg, 'enablePost2');
        // TODO: add more effects toggles and parameters here
    };

    window.handle_load.push(init);
})();
