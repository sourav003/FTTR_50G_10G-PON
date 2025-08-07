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
        double load = default(0.1);						// this will vary as 0.05:0.05:1
        double dataRate = default(50e9/16);				//max datarate in bps

        //@signal[generation](type="double");
        //@statistic[pkt_interval](title="packet inter-arrival time"; source="generation"; record=vector,stats; interpolationmode=none);
    gates:
        output out;
}

simple XR_Device
{
    parameters:
        @display("i=block/wheelbarrow");
        double frameRate = default(60);		                    // default framerate of XR = 60 fps (can be 90, 120 fps)
        double dataRate = default(40);				        	// for 2K@60fps = 40 Mbps, for 4K@60fps = 90 Mbps, for 8K@60fps = 360 Mbps

        //@signal[generation](type="double");
        //@statistic[pkt_interval](title="packet inter-arrival time"; source="generation"; record=vector,stats; interpolationmode=none);

    gates:
        output out;
}

simple ONU
{
    parameters:
        @signal[bkg_latency](type="double");
        @statistic[bkg_packet_latency](title="Background packet latency at ONU"; source="bkg_latency"; record=vector,stats; interpolationmode=none);
        @signal[xr_latency](type="double");
        @statistic[xr_packet_latency](title="XR packet latency at ONU"; source="xr_latency"; record=vector,stats; interpolationmode=none);        

        @display("i=device/smallrouter");

    gates:
        input inSrc_bkg;
        input inSrc_xr;
        input SpltGate_i;
        output SpltGate_o;
}

simple OLT
{
    parameters:
        @display("i=device/router");
        int NumberOfONUs = default(2);
        double ber = default(1e-9);  						// bit error rate

    gates:
        input SpltGate_i;
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
        double datarate = default(50e9);

    types:
        channel PON_Channel extends ned.DatarateChannel
        {
            volatile double distance @unit(km) = default(10 km);
            delay = this.distance/(2e5 km)*1s;					// considering speed of light in fiber = 2x10^5 km/s
            datarate = 50 Gbps;
        }

    submodules:
        olt: OLT {
            @display("p=34,138");
        }
        splitter: Splitter {
            @display("p=151,138");
        }
        onus[olt.NumberOfONUs]: ONU {
            @display("p=387,91,c");
        }
        sources_bkg[olt.NumberOfONUs]: Background_Device {
            @display("p=535,31,c");
        }
        sources_xr[olt.NumberOfONUs]: XR_Device {
            @display("p=621,92,c");
        }


    connections:
        // OLT-Splitter connections
        olt.SpltGate_o --> PON_Channel --> splitter.OltGate_i;
        olt.SpltGate_i <-- PON_Channel <-- splitter.OltGate_o;
        for i=0..(olt.NumberOfONUs-1) {
            splitter.OnuGate_o++ --> PON_Channel --> onus[i].SpltGate_i;		// ONU-Splitter connections
            //splitter.OnuGate++ <--> PON_Channel{distance = uniform(5km,10km);} <--> onus[i].SpltGate;
            splitter.OnuGate_i++ <-- PON_Channel <-- onus[i].SpltGate_o;
            onus[i].inSrc_bkg <-- sources_bkg[i].out; 								// App-ONU connections
            onus[i].inSrc_xr <-- sources_xr[i].out;
        }
}











