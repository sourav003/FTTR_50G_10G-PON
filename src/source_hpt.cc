/*
 * source_hpt.cc
 *
 *  Created on: 8 Aug 2025
 *      Author: mondals
 */

#include <string.h>
#include <math.h>
#include <omnetpp.h>
#include <numeric>   // Required for std::iota
#include <algorithm> // Required for std::sort

#include "sim_params.h"
#include "ethPacket_m.h"
#include "ping_m.h"
#include "gtc_header_m.h"

using namespace std;
using namespace omnetpp;

/*
 * Each source generates packets following some probability distribution.
 * The average inter-arrival time is derived using the maximum datarate of the
 * SourceApp and average packet size.
 * The generateEvent is a self-message which is scheduled back-to-back to create
 * a new packet. Immediately the packet is transmitted to the corresponding ONU.
 */

class Haptic_Device : public cSimpleModule
{
    private:
        double avgFrameSize;
        double avgDataRate;
        double ArrivalRate;
        double pkt_interval;                     // inter-packet generation interval
        double pkt_size;
        cMessage *generateEvent = nullptr;       // holds pointer to the self-timeout message

        //simsignal_t arrivalSignal;               // to send signals for statistics collection

    public:
        virtual ~Haptic_Device();

    protected:
        // The following redefined virtual function holds the algorithm.
        virtual void initialize() override;
        virtual void handleMessage(cMessage *msg) override;
        virtual ethPacket *generateNewPacket();
};

// The module class needs to be registered with OMNeT++
Define_Module(Haptic_Device);

Haptic_Device::~Haptic_Device()
{
    cancelAndDelete(generateEvent);
}

void Haptic_Device::initialize()
{
    //arrivalSignal = registerSignal("generation");               // registering the signal

    avgDataRate = par("dataRate");                              // get the load factor from NED file
    ArrivalRate = par("frameRate");                             // get the max ONU datarate from NED file

    // Initialize variables
    double mean = 1.0/ArrivalRate;
    double std = 2e-3;                             // 10.5 % of mean
    pkt_interval = truncnormal(mean, std);                       // packet inter-arrival times are generated following truncnormal distribution
    generateEvent = new cMessage("generateEvent");              // self-message is generated for next packet generation
    //emit(arrivalSignal,pkt_interval);

    avgFrameSize = avgDataRate/(8*ArrivalRate);                        // framesize = datarate (bps)/(8*fps)
    double frameSize = truncnormal(avgFrameSize, 0.105*avgFrameSize);
    //double frameSize = 0.5*avgFrameSize;

    int num_pkts = ceil(frameSize/1500);
    //EV << "[srcXR" << getIndex() << "] frame size = " << frameSize << ", num_pkts = "<< num_pkts << " and current time = " << simTime() << endl;

    pkt_size = 64;
    for(int i=1;i<num_pkts;i++){
        pkt_size = 1542;
        ethPacket *pkt = generateNewPacket();                       // generating the first packet at T = 0
        send(pkt,"out");
        //EV << "[srcXR" << getIndex() << "] pkt_interval = " << pkt_interval << " and current time = " << simTime() << endl;
    }
    // sending the last packet
    int pending = ceil(frameSize-(num_pkts-1)*1500);
    pkt_size = min(1500,pending)+42;
    ethPacket *pkt = generateNewPacket();                       // generating the first packet at T = 0
    send(pkt,"out");
    //EV << "[srcXR" << getIndex() << "] pkt_interval = " << pkt_interval << " and current time = " << simTime() << endl;

    scheduleAt(simTime()+pkt_interval, generateEvent);          // scheduling the next packet generation
}

void Haptic_Device::handleMessage(cMessage *msg)
{
    if(strcmp(msg->getName(),"generateEvent") == 0) {
        double frameSize = truncnormal(avgFrameSize, 0.105*avgFrameSize);
        //double frameSize = 0.5*avgFrameSize;
        //EV << "[srcXR" << getIndex() << "] frame size = " << frameSize << " and current time = " << simTime() << endl;
        int num_pkts = ceil(frameSize/1500);
        //EV << "[srcXR" << getIndex() << "] frame size = " << frameSize << ", num_pkts = "<< num_pkts << " and current time = " << simTime() << endl;

        pkt_size = 64;
        for(int i=1;i<num_pkts;i++){
            pkt_size = 1542;
            ethPacket *pkt = generateNewPacket();                       // generating the first packet at T = 0
            send(pkt,"out");
            //EV << "[srcXR] pkt_interval = " << pkt_interval << " and current time = " << simTime() << endl;
        }
        // sending the last packet
        int pending = ceil(frameSize-(num_pkts-1)*1500);
        pkt_size = min(1500,pending)+42;
        ethPacket *pkt = generateNewPacket();                           // generating the first packet at T = 0
        send(pkt,"out");
        //EV << "[srcXR" << getIndex() << "] pkt_interval = " << pkt_interval << " and current time = " << simTime() << endl;

        double mean = 1.0/ArrivalRate;
        double std = 2e-3;
        pkt_interval = truncnormal(mean, std);                       // packet inter-arrival times are generated following truncnormal distribution

        scheduleAt(simTime()+pkt_interval, generateEvent);          // scheduling the next packet generation
        //emit(arrivalSignal,pkt_interval);
        //EV << "[srcXR" << getIndex() << "] pkt_interval = " << pkt_interval << " and current time = " << simTime() << endl;
    }
}

ethPacket *Haptic_Device::generateNewPacket()
{
    ethPacket *pkt = new ethPacket("xr_data");
    pkt->setByteLength(pkt_size);                              // generating packets of same size
    pkt->setGenerationTime(simTime());
    //EV << "[srcXR" << getIndex() << "] New packet generated with size (bytes): " << pkt_size << endl;
    return pkt;
}


