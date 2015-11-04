var cfg;

(function() {
    'use strict';

    var Cfg = function() {
        // TODO: Define config fields and defaults here
        this.debugView = -1;
        this.debugScissor = false;
        this.enableToonShade = false;
        this.enableMBlur = false;
        this.tiledBased = false;
        this.tiledBasedDebug = false;
        this.enableBloomGaussian = false;
    };

    var init = function() {
        cfg = new Cfg();

        var gui = new dat.GUI();
        // TODO: Define any other possible config values
        gui.add(cfg, 'debugView', {
            'None':             -1,
            '0 Depth':           0,
            '1 Position':        1,
            '2 Color map':       2,
            '3 Surface normal':  3
        });
        gui.add(cfg, 'debugScissor');
        gui.add(cfg, 'tiledBased');
        gui.add(cfg, 'tiledBasedDebug');

        var eff0 = gui.addFolder('Effects');
        eff0.open();
        eff0.add(cfg, 'enableToonShade');
        // TODO: add more effects toggles and parameters here
        eff0.add(cfg, 'enableMBlur');
        eff0.add(cfg, 'enableBloomGaussian');
    };

    window.handle_load.push(init);
})();
