var cfg;

(function() {
    'use strict';

    var Cfg = function() {
        // TODO: Define config fields and defaults here
        this.debugView = -1;
		this.debug = false;
        this.primitive = 0;
				
//        this.enableEffect0 = false;
		
		this.toon = false;
		this.bloom = false;
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
		
		gui.add(cfg, 'debug');

		
        gui.add(cfg, 'primitive', {
            '0 Scissor':  0,
            '1 Sphere':   1
        });
		
        var eff0 = gui.addFolder('Effects');
        eff0.open();
        eff0.add(cfg, 'toon');
		eff0.add(cfg, 'bloom');
        // TODO: add more effects toggles and parameters here
    };

    window.handle_load.push(init);
})();
