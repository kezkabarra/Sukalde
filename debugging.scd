(
~pathSamples = PathName(thisProcess.nowExecutingPath).parentPath++"Samples/";
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
}.value; // Hau ebaluatzean funtzioa definitzen baino ez gara ari. Ez da funtzioa exekutatzen!

SynthDef(\bpfbuf, {
		arg atk=0, sus=3, rel=0, c1=1, c2=(-1),
		buf=0, rate=1, spos=0, freq=440, rq=1, bpfmix=0,
		pan=0, amp=1, out=0;
		var sig, env;
	    // env = EnvGen.kr(Env([0,1,1,0],[atk,sus,rel],[c1,0,c2]),doneAction:2);
	sig = PlayBuf.ar(2, buf, rate*BufRateScale.ir(buf),startPos:spos);
	// sig = [PinkNoise.ar(0.1), PinkNoise.ar(0.5)];
		// sig = XFade2.ar(sig, BPF.ar(sig, freq, rq, 1/rq.sqrt), bpfmix*2-1);
		// sig = sig * env;
	sig = Balance2.ar(sig[0],sig[1],1, amp);
		Out.ar(out, sig);
	}).add;
)

(
t = TempoClock(120/60);
Pdef(\zarata, Pbind(
			\instrument,\bpfbuf,
			\buf,Pseq([b[\Zarata][0],b[\][1]],inf),
			\sus,Pseq([2, 2],inf),\rel,0,
			\amp,Pseq([0.5,0.3],inf),
			\dur,Pseq([4, 4],inf),
			\pan,1
		)).play(t,quant:4);
)