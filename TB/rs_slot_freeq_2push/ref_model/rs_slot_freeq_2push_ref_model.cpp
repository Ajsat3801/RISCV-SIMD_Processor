#include <svdpi.h>
#include <map>
#include <deque>
#include <vector>

typedef std::vector<uint32_t> T;

class rs_slot_freeq_2push_ref_model {
    private:
        int size;
        int numwords;
        std::deque<T> buffer;

        void reset_buffer(){
            buffer.clear();

            for(int i=0; i<size; i++){
                T buffer_data;
                buffer_data.push_back(i);
                for(int j=1; j<numwords; j++) buffer_data.push_back(0);
                buffer.push_back(buffer_data);
            }
        }
    public:
        rs_slot_freeq_2push_ref_model(int size, int numwords){
            this->size = size;
            this->numwords = numwords;
        }
        void push(const svBitVecVal* push_data){ 
            T buffer_data;
            for(int i=0; i<numwords; i++){
                buffer_data.push_back(push_data[i]);
            }
            buffer.push_back(buffer_data);
        }
        void pop()   { buffer.pop_front();}
        void reset() { reset_buffer();}
        bool empty() { return buffer.empty();}
        bool full()  { return !(buffer.size() < size);}

        void head(svBitVecVal* val){
            // writes the head of the buffer into mem address of val
            T valT = buffer.front();
            for(int i=0; i<numwords; i++){
                val[i] = valT[i];
            }
        }
        void zeros(svBitVecVal* zeros){
            // Helper function for sending 0s as the output
            for(int i=0; i<numwords; i++) zeros[i] = 0;
        }
        void send_to_output(svBitVecVal* dst, svBitVecVal* src){
            // writes values of source mem address into destination mem address
            for(int i=0; i<numwords; i++) dst[i] = src[i];
        }
};

rs_slot_freeq_2push_ref_model* ref_model;

extern "C" void rs_slot_freeq_2push_create_model(
    int size,
    int numwords
){
    ref_model = new rs_slot_freeq_2push_ref_model(size, numwords);
}

extern "C" void rs_slot_freeq_2push_run_model(
    svBit reset_n,
    svBitVecVal* push_data1,
    svBitVecVal* push_data2,
    svBit push1,
    svBit push2,
    svBit pop,
    svBitVecVal* data_out,
    svBit* fifo_full,
    svBit* fifo_empty
) {  
    /*
     * Modelling behavior of DUT
     * Important Note: because FIFO is FWFT, the output is the result of the
     * operations of the previous cycle.
     * Example: if cycle N has a pop, the the data_out reflects the pop at
     * cycle N+1. The same applies for full and empty
    */

    // state variables covering all valid cases
    bool empty = ref_model->empty();
    bool full = ref_model->full();

    bool bypass_data1 = push1 && pop && empty;
    bool bypass_data2 = !push1 && push2 && pop && empty;
    bool push1_allowed = push1 && !full && !bypass_data1;
    bool push2_allowed = push2 && !full && !bypass_data2;
    bool pop_allowed = pop && !empty && !bypass_data1 && !bypass_data2;

    // reading the result of the operations done in the previous cycle
    if(bypass_data1) ref_model->send_to_output(data_out, push_data1);
    else if(bypass_data2) ref_model->send_to_output(data_out, push_data2);
    else if(ref_model->empty()) ref_model->zeros(data_out);
    else ref_model->head(data_out);

    *fifo_full = ref_model->full() ? 1 : 0;
    *fifo_empty = ref_model->empty() ? 1 : 0;

    // operations done in the current cycle
    if(!reset_n){
        ref_model->reset();
        ref_model->head(data_out);
    } 
    else {
        // if multiple valid, inherent priority for data1 over data2
        if(push1_allowed) ref_model->push(push_data1);
        if(push2_allowed) ref_model->push(push_data2);

        if(pop_allowed)  ref_model->pop();
        
    }
}