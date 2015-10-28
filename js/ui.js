var cfg;

(function() {
    'use strict';

    var Cfg = function() {
        // TODO: Define config fields and defaults here
        this.debugView = -1;
        this.debugScissor = false;
        // change scissor algorithm Default: -1; 
        this.scissor = 0;
        this.enableEffect = 1;
        //
        this.lightNumber = 20;
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
        gui.add(cfg, 'lightNumber', {
            '20' : 20,
            '40' : 40,
            '80' : 80,
            '160': 160,
            '320': 320
        });

        var optim0 = gui.addFolder('OPTIMIZATION');
        optim0.add(cfg, 'debugScissor');
        optim0.add(cfg, 'scissor',{
            'None':              -1,
            '0 Default':          0,
            '1 AABB':             1     
        });
        
        var eff0 = gui.addFolder('EFFECTS');
        eff0.add(cfg, 'enableEffect',{
            '1 Default':         1,
            '2 Toon':            2,
            '3 Bloom':           3
        
        });
        // add line numbers 
        // TODO: add more effects toggles and parameters here
    };

    window.handle_load.push(init);
})();