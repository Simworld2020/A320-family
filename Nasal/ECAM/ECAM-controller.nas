# A3XX Electronic Centralised Aircraft Monitoring System
# Copyright (c) 2019 Jonathan Redpath (legoboyvdlp)

var leftmsgEnable = props.globals.initNode("/ECAM/show-left-msg", 1, "BOOL");
var rightmsgEnable = props.globals.initNode("/ECAM/show-right-msg", 1, "BOOL");

var lines = [props.globals.getNode("/ECAM/msg/line1", 1), props.globals.getNode("/ECAM/msg/line2", 1), props.globals.getNode("/ECAM/msg/line3", 1), props.globals.getNode("/ECAM/msg/line4", 1), props.globals.getNode("/ECAM/msg/line5", 1), props.globals.getNode("/ECAM/msg/line6", 1), props.globals.getNode("/ECAM/msg/line7", 1), props.globals.getNode("/ECAM/msg/line8", 1)];
var linesCol = [props.globals.getNode("/ECAM/msg/linec1", 1), props.globals.getNode("/ECAM/msg/linec2", 1), props.globals.getNode("/ECAM/msg/linec3", 1), props.globals.getNode("/ECAM/msg/linec4", 1), props.globals.getNode("/ECAM/msg/linec5", 1), props.globals.getNode("/ECAM/msg/linec6", 1), props.globals.getNode("/ECAM/msg/linec7", 1), props.globals.getNode("/ECAM/msg/linec8", 1)];
var rightLines = [props.globals.getNode("/ECAM/rightmsg/line1", 1), props.globals.getNode("/ECAM/rightmsg/line2", 1), props.globals.getNode("/ECAM/rightmsg/line3", 1), props.globals.getNode("/ECAM/rightmsg/line4", 1), props.globals.getNode("/ECAM/rightmsg/line5", 1), props.globals.getNode("/ECAM/rightmsg/line6", 1), props.globals.getNode("/ECAM/rightmsg/line7", 1), props.globals.getNode("/ECAM/rightmsg/line8", 1)];
var rightLinesCol = [props.globals.getNode("/ECAM/rightmsg/linec1", 1), props.globals.getNode("/ECAM/rightmsg/linec2", 1), props.globals.getNode("/ECAM/rightmsg/linec3", 1), props.globals.getNode("/ECAM/rightmsg/linec4", 1), props.globals.getNode("/ECAM/rightmsg/linec5", 1), props.globals.getNode("/ECAM/rightmsg/linec6", 1), props.globals.getNode("/ECAM/rightmsg/linec7", 1), props.globals.getNode("/ECAM/rightmsg/linec8", 1)];
var statusLines = [props.globals.getNode("/ECAM/status/line1", 1), props.globals.getNode("/ECAM/status/line2", 1), props.globals.getNode("/ECAM/status/line3", 1), props.globals.getNode("/ECAM/status/line4", 1), props.globals.getNode("/ECAM/status/line5", 1), props.globals.getNode("/ECAM/status/line6", 1), props.globals.getNode("/ECAM/status/line7", 1), props.globals.getNode("/ECAM/status/line8", 1)];
var statusLinesCol = [props.globals.getNode("/ECAM/status/linec1", 1), props.globals.getNode("/ECAM/status/linec2", 1), props.globals.getNode("/ECAM/status/linec3", 1), props.globals.getNode("/ECAM/status/linec4", 1), props.globals.getNode("/ECAM/status/linec5", 1), props.globals.getNode("/ECAM/status/linec6", 1), props.globals.getNode("/ECAM/status/linec7", 1), props.globals.getNode("/ECAM/status/linec8", 1)];

var leftOverflow  = props.globals.initNode("/ECAM/warnings/overflow-left", 0, "BOOL");
var rightOverflow = props.globals.initNode("/ECAM/warnings/overflow-right", 0, "BOOL");
var overflow = props.globals.initNode("/ECAM/warnings/overflow", 0, "BOOL");

var dc_ess = props.globals.getNode("/systems/electrical/bus/dc-ess", 1);

var lights = [props.globals.initNode("/ECAM/warnings/master-warning-light", 0, "BOOL"), props.globals.initNode("/ECAM/warnings/master-caution-light", 0, "BOOL")]; 
var aural = [props.globals.initNode("/sim/sound/warnings/crc", 0, "BOOL"), props.globals.initNode("/sim/sound/warnings/chime", 0, "BOOL")];
var warningFlash = props.globals.initNode("/ECAM/warnings/master-warning-flash", 0, "BOOL");

var lineIndex = 0;
var rightLineIndex = 0;
var statusIndex = 0;

var flash = 0;
var hasCleared = 0;
var statusFlag = 0;

var warning = {
	new: func(msg,colour = "g",aural = 9,light = 9,hasSubmsg = 0,lastSubmsg = 0, sdPage = "nil") {
		var t = {parents:[warning]};
		
		t.msg = msg;
		t.colour = colour;
		t.aural = aural;
		t.light = light;
		t.hasSubmsg = hasSubmsg;
		t.lastSubmsg = lastSubmsg;
		t.active = 0;
		t.noRepeat = 0;
		t.noRepeat2 = 0;
		t.clearFlag = 0;
		t.sdPage = sdPage;
		t.hasCalled = 0;
		
		return t
	},
	write: func() {
		if (me.active == 0) { return; }
		lineIndex = 0;
		while (lineIndex < 7 and lines[lineIndex].getValue() != "") {
			lineIndex = lineIndex + 1; # go to next line until empty line
		}
		
		if (lineIndex == 7) {
			leftOverflow.setBoolValue(1);
		} elsif (leftOverflow.getBoolValue()) {
			leftOverflow.setBoolValue(0);
		}
		
		if (lines[lineIndex].getValue() == "" and me.msg != "" and lineIndex <= 7) { # at empty line. Also checks if message is not blank to allow for some warnings with no displayed msg, eg stall
			lines[lineIndex].setValue(me.msg);
			linesCol[lineIndex].setValue(me.colour);
		}
	},
	warnlight: func() {
		if (me.light > 1 or me.noRepeat == 1 or me.active == 0) {return;}
		lights[me.light].setBoolValue(1);
		me.noRepeat = 1;
	},
	sound: func() {
        if (me.aural > 1 or me.noRepeat2 == 1 or me.active == 0) {return;}
		if (me.aural != 0) {
			aural[me.aural].setBoolValue(0); 
		}
        me.noRepeat2 = 1;
		settimer(func() {
			aural[me.aural].setBoolValue(1);
		}, 0.15);
    },
	callPage: func() {
		if (me.sdPage == "nil" or me.hasCalled == 1) { return; }
		#libraries.LowerECAM.failCall(me.sdPage);
		me.hasCalled = 1;
	}
};

var memo = {
	new: func(msg,colour = "g") {
		var t = {parents:[memo]};
		
		t.msg = msg;
		t.colour = colour;
		t.active = 0;
		
		return t
	},
	write: func() {
		if (me.active == 1) {
			rightLineIndex = 0;
			while (rightLines[rightLineIndex].getValue() != "" and rightLineIndex <= 7) {
				rightLineIndex = rightLineIndex + 1; # go to next line until empty line
			} 
			
			if (rightLineIndex > 7) {
				rightOverflow.setBoolValue(1);
			} elsif (rightOverflow.getBoolValue()) {
				rightOverflow.setBoolValue(0);
			}
			
			if (rightLines[rightLineIndex].getValue() == "" and rightLineIndex <= 7) { # at empty line
				rightLines[rightLineIndex].setValue(me.msg);
				rightLinesCol[rightLineIndex].setValue(me.colour);
			}
		}
	},
};

var status = {
	new: func(msg,colour) {
		var t = {parents:[status]};
		
		t.msg = msg;
		t.colour = colour;
		t.active = 0;
		
		return t
	},
	write: func() {
		if (me.active == 1) {
			statusIndex = 0;
			while (statusLines[statusIndex].getValue() != "" and statusIndex <= 7) {
				statusIndex = statusIndex + 1; # go to next line until empty line
			} 
			
			if (statusLines[statusIndex].getValue() == "" and statusIndex <= 7) { # at empty line
				statusLines[rightLineIndex].setValue(me.msg);
				statusLinesCol[rightLineIndex].setValue(me.colour);
			}
		}
	},
};

var ECAM_controller = {
	init: func() {
		ECAMloopTimer.start();
		me.reset();
	},
	loop: func() {
		# check active messages
		if ((systems.ELEC.Bus.acEss.getValue() >= 110 or systems.ELEC.Bus.ac2.getValue() >= 110) and !getprop("/systems/acconfig/acconfig-running")) {
			messages_priority_3();
			messages_priority_2();
			messages_priority_1();
			messages_priority_0();
			messages_memo();
			messages_right_memo();
		} else {
			foreach (var w; warnings.vector) {
				w.active = 0;
			}
			shutUpYou();
		}
		
		# clear display momentarily
		
		
		for(var n = 0; n <= 7; n += 1) {
			lines[n].setValue("");
		}
		
		for(var n = 0; n <= 7; n += 1) {
			rightLines[n].setValue("");
		}
		
		# write to ECAM
		var counter = 0;
		
		foreach (var w; warnings.vector) {
			if (counter >= 9) { break; }
			if (w.active == 1) {
				w.write();
				w.warnlight();
				w.sound();
				counter += 1;
			}
		}
		
		if (lines[0].getValue() == "" and flash == 0) { # disable left memos if a warning exists. Warnings are processed first, so this stops leftmemos if line1 is not empty
			foreach (var l; leftmemos.vector) {
				l.write();
			}
		}
		
		foreach (var sL; specialLines.vector) {
			sL.write();
		}
		
		foreach (var sF; secondaryFailures.vector) {
			sF.write();
		}
		
		foreach (var m; memos.vector) {
			m.write();
		}
		
		if (leftOverflow.getBoolValue() == 1 or leftOverflow.getBoolValue() == 1) {
			overflow.setBoolValue(1);
		} elsif (leftOverflow.getBoolValue() == 0 and leftOverflow.getBoolValue() == 0) {
			overflow.setBoolValue(0);
		}
	},
	reset: func() {
		foreach (var w; warnings.vector) {
			if (w.active == 1) {
				w.active = 0;
			}
		}
		
		foreach (var l; leftmemos.vector) {
			if (l.active == 1) {
				l.active = 0;
			}
		}
		
		foreach (var sL; specialLines.vector) {
			if (sL.active == 1) {
				sL.active = 0;
			}
		}
		
		foreach (var sF; secondaryFailures.vector) {
			if (sF.active == 1) {
				sF.active = 0;
			}
		}
		
		foreach (var m; memos.vector) {
			if (m.active == 1) {
				m.active = 0;
			}
		}
	},
	clear: func() {
		hasCleared = 0;
		counter = 0;
		
		if (leftOverflow.getBoolValue()) {
			foreach (var w; warnings.vector) {
				if (counter >= 8) { break; }
				if (w.active == 1 and w.clearFlag != 1) {
					counter += 1;
					if (w.hasSubmsg == 1) { continue; }
					w.clearFlag = 1;
					hasCleared = 1;
					statusFlag = 1;
				}
			}
		} else {
			foreach (var w; warnings.vector) {
				if (w.active == 1 and w.clearFlag != 1 and w.hasSubmsg == 1) {
					w.clearFlag = 1;
					hasCleared = 1;
					statusFlag = 1;
					break;
				}
			}
		}
		
		if (statusFlag == 1) {
			libraries.LowerECAM.failCall("sts");
			statusFlag = 0;
		}
	},
	recall: func() {
		foreach (var w; warnings.vector) {
			if (w.clearFlag == 1) {
				w.noRepeat = 0;
				w.clearFlag = 0;
			}
		}
	},
	warningReset: func(warning) {
		warning.active = 0;
		warning.noRepeat = 0;
		warning.noRepeat2 = 0;
	},
};

setlistener("/systems/electrical/bus/dc-ess", func {
	if (dc_ess.getValue() < 25) {
		ECAM_controller.reset();
	}
}, 0, 0);

var ECAMloopTimer = maketimer(0.15, func {
	ECAM_controller.loop();
});

# Flash Master Warning Light
var shutUpYou = func() {
	lights[0].setBoolValue(0);
}

var warnTimer = maketimer(0.25, func {
	if (!lights[0].getBoolValue()) {
		warnTimer.stop();
		warningFlash.setBoolValue(0);
	} else if (!warningFlash.getBoolValue()) {
		warningFlash.setBoolValue(1);
	} else {
		warningFlash.setBoolValue(0);
	}
});

setlistener("/ECAM/warnings/master-warning-light", func {
	if (lights[0].getBoolValue()) {
		warningFlash.setBoolValue(0);
		warnTimer.start();
	} else {
		warnTimer.stop();
		warningFlash.setBoolValue(0);
	}
}, 0, 0);