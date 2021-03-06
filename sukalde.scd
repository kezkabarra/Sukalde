(
//1. server config
s = Server.local;

//Server.default.options.device = "sSC"; // to set the client name to register with Jack ("my_synth")
//Server.default.options.device = "JACKServerName:scsynthName"; //to use a specific JACK server, as well as set the client name
//A nil device is equivalent to Server.default.options.device = "default:SuperCollider";
/*
//The JACK connections can be configured via the environment variables SC_JACK_DEFAULT_INPUTS and SC_JACK_DEFAULT_OUTPUTS. The format is either a string that specifies another jack client or a comma-separated list of jack ports.
// connect first to input channels with system
"SC_JACK_DEFAULT_INPUTS".setenv("system:capture_1,system:capture_2");
// connect all output channels with system
"SC_JACK_DEFAULT_OUTPUTS".setenv("system");
*/

s.options.numOutputBusChannels_(2);
s.options.numInputBusChannels_(2);
s.options.sampleRate_(44100);
s.options.memSize_(2.pow(15)); // kB-etan! Kontuz portatilean! //The default is 8192 kB

// 50.do{{DelayN.ar(PinkNoise.ar(0.05),1,1)}.play;} //memSize maximoa probatzeko 44100*.....
s.newBusAllocators; // Busen indize kontagailua hasieratzeko. Pilatu egiten dira eta bestela.

ServerBoot.removeAll;
ServerTree.removeAll;
ServerQuit.removeAll;

//2. initialize global variables
~out = 0;
~pathGit = PathName(thisProcess.nowExecutingPath).parentPath;
~pathSamples = PathName(thisProcess.nowExecutingPath).parentPath++"Samples/";
t = TempoClock(80/60); // Ez dakit oraindik hemen egin beharko nukeen, baina, oraingoz, hementxe utziko dut
~barDur = 4/t.tempo; // <-- 60/bpm * beat_per_bar // Barra batek zenbat segundu

//3. define piece-specific functions
~makeBuffers = {
	b = Dictionary.new;
	PathName(~pathSamples).entries.do{
		arg subfolder;
		b.add(
			subfolder.folderName.asSymbol ->
			Array.fill(
				subfolder.entries.size,
				{
					arg i;
					Buffer.read(s, subfolder.entries[i].fullPath);
				}
			)
		);
	};
}; // Hau ebaluatzean funtzioa definitzen baino ez gara ari. Ez da funtzioa exekutatzen!


~makeBusses = {
	~bus = Dictionary.new;
	~bus.add(\reverb -> Bus.audio(s,2));
};// Kontuz! ServerTree-n erregistratzea akatsa litzateke. Cmd+. bakoitzeko busa gainezarri baino, beste bat (indize pauso bat haratago) sortuko litzateke.

~cleanup = {
	s.newBusAllocators; // Bus indizea erreseteatu
	s.newNodeAllocators; // Nodoen indizea hasieratu ()
	ServerBoot.removeAll; // ServerBoot-en izena emandako funtzio denak izena kendu
	ServerQuit.removeAll; // ServerQuit-en izena emandako funtzio denak izena kendu
	ServerTree.removeAll; // ServerTree-en izena emandako funtzio denak izena kendu
};

~makeNodes = {
	s.bind({ //dena aldi berean (sorta (bundle) batean) exekutatuko dela ziurtatzeko
		s.newNodeAllocators; // Nodoen indizeak hasieratzeko (IKE)
		~mainGrp = Group.new;
		~reverbGrp = Group.after(~mainGrp); // irakur funtzio bukaeran
		~reverbSynth = Synth.new(
			\reverb,
			[
				\amp, 1,
				\predelay,0.2, //0.1,
				\revtime,1.8, //1.8,
				\lpf, 4500,
				\mix, 0.35,
				\in, ~bus[\reverb],
				\out, ~out,
			],
			~reverbGrp
		);
	});
};// Efektuak (reverb, delay... Synthak, finean) instantziatu egin behar dira. Eta, gainera, berauek erabiltzen dituzten Synthak baino lehen (beherago egon behar dute NodeTreean).

~makeEvents = {
	//MIDIIn.connectAll;
	e = Dictionary.new;

	e.add(\event1 -> {
		Pdef(\zarata, Pbind(
			\instrument,\bpfbuf,
			\buf,Pseq([b[\Zarata][0],b[\Zarata][1]],inf),
			\sus,Pseq([2, 2],inf),\rel,0,
			\amp,Pseq([0.5,0.3],inf),
			\dur,Pseq([4, 4],inf),
			\pan,1
		)).play(t,quant:4);

		Pdef(\dunbal, Pbind(
			\instrument,\bpfbuf,
			\buf,b[\Dunbal],
			\amp,0.5,
			\pan,0,
			\dur,Pseq([1,3],inf)
		)).play(t,quant:4);
	});

	e.add(\event2 ->{
/*		Pdef(\goilarak,Pbind(
			\instrument, \bpfbuf,
			\buf,Pxrand(b[\Goilarak].value.collect({arg a; a.bufnum}),inf),
			\dur,Pwhite(0.75/4,1.25/4),
			\amp,0.1,
			\pan,1
		)).play(t,quant:[4,2]);*/

		Pdef(\gitar,Pbind(
			\instrument, \bpfbuf,
			\buf,b[\Gitar],
			\sus,5,
			\dur,8,
			\amp,1,
			\pan,0
		)).play(t,quant:[4]);


/*		Pbindef(\,\dur,Pseq([3,1,3,1,3,1,3,1,]/4,inf),\amp,Pwhite(0.5,0.8,inf));
		Pbindef(\snare,\dur,Pbjorklund2(26,32,inf)/4,\amp,Pif(Pbinop('==', Pkey(\buf), 12),1,0.7));
		Pbindef(\bell,\dur,1/4,\amp,0.25);*/
	});
	e.add(\event3 ->{
		Pdef(\baxu,Pbind(
			\instrument, \bpfbuf,
			\buf,b[\Baxu],
			\sus,10,
			\dur,8,
			\amp,1,
			\pan,0
		)).play(t,quant:[4,1]);

	});

/*	MIDIdef.cc(\controller, { //Continious Controller messages
		arg val, num;
		case
		{num==73 && val==127} {e[\event1].value;"event1".postln;}
		{num==74 && val==127} {e[\event2].value;"event2".postln;}
		{num==75 && val==127} {e[\event3].value;"event3".postln;}
		{num==76 && val==127} {e[\event4].value;"event4".postln;}
		{num==77 && val==127} {e[\event5].value;"event5".postln;}
		{num==82 && val==127} {e[\oneshot1].value;"oneshot1".postln;}
		{num==83 && val==127} {e[\oneshot2].value;"oneshot2".postln;}
		{num==84 && val==127} {e[\oneshot3].value;"oneshot3".postln;}
		{true} {nil};
	});*/
};

//4. register functions with ServerBoot/Quit/Tree
ServerBoot.add(~makeBuffers);
ServerBoot.add(~makeBusses);
ServerQuit.add(~cleanup);

//5. boot server
s.waitForBoot({ // (GUI-a onartzen duen) AppClock gainean dabilen Routine-a (exekuzioa gelditzea baimentzen duen bakarra (wait,s.sync...)) sortzen du automatikoki ezkutuan.

s.sync; // Zeregin asinkronkoek (Buffer.read, SynthDef...) buka dezaten itxaroten du. Kasu honetan, zerbitzariak egin behar duena (ServerBoot-en erregistratutako funtzioak exekutatu, adibidez) egin dezala itxaron.

//6a. SynthDefs

	SynthDef(\bpfbuf, {
		arg atk=0, sus=3, rel=0, c1=1, c2=(-1),
		buf=0, rate=1, spos=0, freq=440, rq=1, bpfmix=0,
		pan=0, amp=1, out=0;
		var sig, env;
		env = EnvGen.kr(Env([0,1,1,0],[atk,sus,rel],[c1,0,c2]),doneAction:2);
		sig = PlayBuf.ar(2, buf, rate*BufRateScale.ir(buf),startPos:spos);
		sig = XFade2.ar(sig, BPF.ar(sig, freq, rq, 1/rq.sqrt), bpfmix*2-1);
		sig = sig * env;
		sig = Balance2.ar(sig[0],sig[1],pan, amp);
		Out.ar(out, sig);
	}).add;

	SynthDef(\reverb, {
		arg in, predelay=0.08, revtime=1.8,
		lpf=4500, mix=0.15, amp=1, out=0;
		var dry, wet, temp, sig;
		dry = In.ar(in,2);
		temp = In.ar(in,2);
		wet = 0;
		temp = DelayN.ar(temp, 0,2, ºpredelay);
		16.do{
			temp = AllpassN.ar(temp, 0.05, {Rand(0.001,0.05)}!2, revtime);
			temp = LPF.ar(temp, lpf);
			wet = wet + temp;
		};
		sig = XFade2.ar(dry, wet, mix*2-1, amp);
		Out.ar(out, sig);
	}).add;

	s.sync;

// 6b. register remaining functions
	ServerTree.add(~makeNodes); // Efektuak (reverb, delay... Synthak, finean) instantziatu egin behar dira. Eta, gainera, berauek erabiltzen dituzten Synthak baino lehen (beherago egon behar dute NodeTreean)
	ServerTree.add(~makeEvents);
	s.freeAll; // cmd+. -ren berdina da! (ServerTree-n erregistratzen diren funtzioak exekutatuko dira)

	s.sync;
	"done".postln;

});
)

// Saioa bera
(t = TempoClock(120/60);
e[\event1].value;)
e[\event2].value;
e[\event3].value;

Pbindef(\gitar,\dur,4)
Pbindef(\goilarak,\dur,4).stop
Pbindef(\zarata).play
Pbindef(\dunbal,\amp,0.5,\pan,1).stop
Pbindef(\snare,out,~bus[\reverb])

Pbindef(\kick,\dur,Pseq([3,1,3,1,3,1,3,1,]/2,inf))
Pbindef(\snare,\dur,Pbjorklund2(26,32,inf)/4)
Pbindef(\bell,\dur,1/4,\amp,0.25)
Synth(\bpfsaw, [\freq, 1.4, \atk, 0.1, \rel, 7, \out, ~bus[\reverb]], ~mainGrp); //reverbare proba egiteko

/* GIT*/
p=Pipe.new("cd"+~pathGit+"&& gnome-terminal", "r"); p.close;