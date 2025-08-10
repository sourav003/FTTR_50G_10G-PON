//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/.
//

simple Background_Device
{
    parameters:
        @display("i=device/pc");
        double load = default(0.3);						// this will vary as 0.05:0.05:1
        //double dataRate = default((50e9-360e6*16)/16);				//max datarate in bps
        double dataRate = default(50e9/(16*8));

        //@signal[generation](type="double");
        //@statistic[pkt_interval](title="packet inter-arrival time"; source="generation"; record=vector,stats; interpolationmode=none);
    gates:
        input in;
        output out;
}

simple XR_Device
{
    parameters:
        @display("i=device/xr");
        double frameRate = default(60);		                    // default framerate of XR = 60 fps (can be 90, 120 fps)
        double dataRate = default(40e6);				        	// for 2K@60fps = 40 Mbps, for 4K@60fps = 90 Mbps, for 8K@60fps = 360 Mbps, for 16K@60 fps = 440 Mbps

        //@signal[generation](type="double");
        //@statistic[pkt_interval](title="packet inter-arrival time"; source="generation"; record=vector,stats; interpolationmode=none);

    gates:
        input in;
        output out;
}

simple HMD_Device
{
    parameters:
        @display("i=block/user");
        double frameRate = default(60);		                    // default framerate of XR = 60 fps (can be 90, 120 fps)
        double dataRate = default(40e6);				        	// for 2K@60fps = 40 Mbps, for 4K@60fps = 90 Mbps, for 8K@60fps = 360 Mbps, for 16K@60 fps = 440 Mbps

        //@signal[generation](type="double");
        //@statistic[pkt_interval](title="packet inter-arrival time"; source="generation"; record=vector,stats; interpolationmode=none);

    gates:
        input in;
        output out;
}

simple Control_Device
{
    parameters:
        @display("i=device/gloves");
        double frameRate = default(60);		                    // default framerate of XR = 60 fps (can be 90, 120 fps)
        double dataRate = default(40e6);				        	// for 2K@60fps = 40 Mbps, for 4K@60fps = 90 Mbps, for 8K@60fps = 360 Mbps, for 16K@60 fps = 440 Mbps

        //@signal[generation](type="double");
        //@statistic[pkt_interval](title="packet inter-arrival time"; source="generation"; record=vector,stats; interpolationmode=none);

    gates:
        input in;
        output out;
}

simple Haptic_Device
{
    parameters:
        @display("i=device/robot_arm");
        double frameRate = default(60);		                    // default framerate of XR = 60 fps (can be 90, 120 fps)
        double dataRate = default(40e6);				        	// for 2K@60fps = 40 Mbps, for 4K@60fps = 90 Mbps, for 8K@60fps = 360 Mbps, for 16K@60 fps = 440 Mbps

        //@signal[generation](type="double");
        //@statistic[pkt_interval](title="packet inter-arrival time"; source="generation"; record=vector,stats; interpolationmode=none);

    gates:
        input in;
        output out;
}

simple WiFi_AP
{
    parameters:
        @display("i=device/accesspoint");

    gates:
        input Sfu_in;
        output Sfu_out;

        input SrcXr_in;
        input SrcHmd_in;
        input SrcHpt_in;
        input SrcCtr_in;
        input SrcBkg_in;

        output SrcXr_out;
        output SrcHmd_out;
        output SrcHpt_out;
        output SrcCtr_out;
        output SrcBkg_out;
}

simple SFU
{
    parameters:
        @signal[bkg_latency](type="double");
        @statistic[bkg_packet_latency](title="Background packet latency at ONU"; source="bkg_latency"; record=vector,stats; interpolationmode=none);
        //@signal[xr_latency](type="double");
        //@statistic[xr_packet_latency](title="XR packet latency at ONU"; source="xr_latency"; record=vector,stats; interpolationmode=none);

        @display("i=device/drive");

    gates:
        input inWap;
        output outWap;
        input SpltGate_in;
        output SpltGate_out;
}

simple ONU
{
    parameters:
        @display("i=device/smallrouter_l");

    gates:
        input inMFU;
        output outMFU;
        input SpltGate_i;
        output SpltGate_o;
}

simple OLT
{
    parameters:
        @display("i=device/lan-ring_vl");
        int NumberOfONUs = default(2);
        double ber = default(1e-9);  						// bit error rate

    gates:
        input SpltGate_i;
        output SpltGate_o;
}

simple MFU
{
    parameters:
        @display("i=block/layer_90");
        int NumberOfSFUs = default(2);

    gates:
        input OnuGate_in;			// for communication with 50G-PON ONUs
        output OnuGate_out;
        input SpltGate_i;			// for communication with 10G-PON Splitters
        output SpltGate_o;
}

simple Splitter
{
    parameters:
        @display("i=block/rxtx");

    gates:
        input OltGate_i;
        output OltGate_o;
        input OnuGate_i[];
        output OnuGate_o[];
}

network FTTR_50G_10GPON
{
    parameters:
        int NumberOfONUs = default(1);
        int NumberOfSFUs = default(1);

    types:
        channel FTTR_Channel extends ned.DatarateChannel
        {
            volatile double distance @unit(km) = default(10 m);
            delay = this.distance/(2e5 km)*1s;					// considering speed of light in fiber = 2x10^5 km/s
            datarate = 10 Gbps;
        }

        channel FTTH_Channel extends ned.DatarateChannel
        {
            volatile double distance @unit(km) = default(10 km);
            delay = this.distance/(2e5 km)*1s;					// considering speed of light in fiber = 2x10^5 km/s
            datarate = 50 Gbps;

        }

    submodules:
        olt: OLT {
            @display("p=64,428");
        }
        splitter_ext: Splitter {
            @display("p=327,428");
        }
        splitter_int[this.NumberOfONUs]: Splitter {
            @display("p=745,296,c");
        }
        onus[this.NumberOfONUs]: ONU {
            @display("p=464,296,c");
        }
        mfus[this.NumberOfONUs]: MFU {
            @display("p=572,296,c");
        }
        sfus[this.NumberOfONUs*this.NumberOfSFUs]: SFU {
            @display("p=882,133,c");
        }
        waps[this.NumberOfONUs*this.NumberOfSFUs]: WiFi_AP {
            @display("p=1016,133,c");
        }
        bkgs[this.NumberOfONUs*this.NumberOfSFUs]: Background_Device {
            @display("p=1202,36,c");
        }
    connections allowunconnected:
        // OLT-Splitter connections
        olt.SpltGate_o --> FTTH_Channel --> splitter_ext.OltGate_i;								// OLT-Splitter connections
        olt.SpltGate_i <-- FTTH_Channel <-- splitter_ext.OltGate_o;
        for i=0..(this.NumberOfONUs-1) {
            splitter_ext.OnuGate_o++ --> FTTH_Channel --> onus[i].SpltGate_i;					// Splitter-ONU connections
            //splitter.OnuGate++ <--> FTTH_Channel{distance = uniform(5km,10km);} <--> onus[i].SpltGate;
            splitter_ext.OnuGate_i++ <-- FTTH_Channel <-- onus[i].SpltGate_o;

            onus[i].inMFU <-- mfus[i].OnuGate_out; 												// ONU-MFU connections
            onus[i].outMFU --> mfus[i].OnuGate_in;

            mfus[i].SpltGate_o --> FTTR_Channel --> splitter_int[i].OltGate_i;					// MFU-Splitter connections
            mfus[i].SpltGate_i <-- FTTR_Channel <-- splitter_int[i].OltGate_o;
        }
        for j=0..(this.NumberOfONUs*this.NumberOfSFUs-1) {
            splitter_int[int(j / this.NumberOfSFUs)].OnuGate_o++ --> FTTR_Channel --> sfus[j].SpltGate_in;
            splitter_int[int(j / this.NumberOfSFUs)].OnuGate_i++ <-- FTTR_Channel <-- sfus[j].SpltGate_out;

            sfus[j].inWap <-- waps[j].Sfu_out;
            sfus[j].outWap --> waps[j].Sfu_in;

            waps[j].SrcBkg_in <-- bkgs[j].out;
            waps[j].SrcBkg_out --> bkgs[j].in;
        }


}











