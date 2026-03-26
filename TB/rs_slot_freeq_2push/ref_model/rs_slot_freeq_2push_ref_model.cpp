#include <svdpi.h>
#include <map>
#include <deque>
#include <vector>

class rs_slot_freeq_2push_ref_model {
    private:
        int size;
        int numwords;
        std::vector<svBitVecVal> buffer;

        void reset_buffer(){
            buffer.clear();

            for(int i=0; i<size; i++){
                svBitVecVal buffer_data;
                buffer_data.push_back(i);
                for(int j=1; j<numwords; j++) buffer_data.push_back(0);
                buffer.push_back(buffer_data);
            }
        }
    public:
        rs_slot_freeq_2_push_ref_model(int size, int numwords){
            this->size = size;
            this->numwords = numwords;
            reset_buffer()
        }
        void push(const svBitVecVal* push_data){ buffer.push_back(push_data);}
        void pop()   { buffer.pop_front();}
        void reset() { reset_buffer();}
        bool empty() { return buffer.empty();}
        bool full()  { return !(buffer.size() < size);}
        svBitVecVal head(){
            svBitVecVal val = buffer.front();
            return val;
        }
        svBitVecVal zeros(){
            svBitVecVal zeros;
            for(int i=0; i<numwords; i++) zeros.push(0);
            return zeros;
        }
};

rs_slot_freeq_2push_ref_model* ref_model;

extern "C" void rs_slot_freeq_2push_create_model(
    int size,
    int numwords
){
    ref_model = rs_slot_freeq_2push_ref_model(size, numwords);
}

extern "C" void rs_slot_freeeq_2push_run_model(
    svBitVecVal* push_data1,
    svBitVecVal* push_data2,
    svBit push1,
    svBit push2,
    svBit pop,
    svBitVecVal* data_out,
    svBit* fifo_full,
    svBit* fifo_empty
) {  
    bool empty = ref_model->empty();
    bool full = ref_model->full();

    bool bypass_data1 = push1 && pop && empty;
    bool bypass_data2 = !push1 && push2 && pop && empty;
    bool push1_allowed = push1 && !full && !bypass_data1;
    bool push2_allowed = push2 && !full && !bypass_data2;
    bool pop_allowed = pop && !empty && !bypass_data1 && !bypass_data2;

    // if multiple valid, we can push data1 first followed by data2, inherent priority given

    if(push1_allowed) ref_model->push(*push_data1);
    if(push2_allowed) ref_model->push(*push_data2);
    if(pop_allowed)   ref_model->pop();

    // setting value of data out, returns 0 if buffer is empty and no output
    if(bypass_data1) *data_out = push_data1;
    else if(bypass_data2) *data_out = push_data2;
    else if(ref_model->empty()) *data_out = ref_model->zeros();
    else *data_out = ref_model->head();

    *fifo_full = ref_model->full() ? 1 : 0;
    *fifo_empty = ref_model->empty() ? 1 : 0;
}