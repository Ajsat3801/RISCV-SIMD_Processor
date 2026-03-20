/*
Circular FIFO FWFT model with modified reset condition,
*/

#include <svdpi.h>
#include <map>
#include <deque>
#include <vector>

typedef std::vector<uint32_t> T;

// Each instance of our FIFO model
class iq_rs_buffer_one_input_ref_model {
    private:
        std::deque<T> buffer;
        int size;
        void repopulate_buffer(int numwords) {
            for(int i=0; i<size; i++) {
                T buffer_val;
                buffer_val.push_back(i);
                for(int j=1;i<numwords;j++) buffer_val.push_back(0);
                buffer.push_back(buffer_val);
            }
        }
    public:
        iq_rs_buffer_one_input_ref_model(int size, int numwords){
            this->size = size;
            repopulate_buffer();
        }
        void push(T data) {
            buffer.push_back(data);
        }
        void pop() {
            buffer.pop_front();
        }
        void reset(int numwords) {
            buffer.clear();
            repopulate_buffer(numwords);
        }
        bool empty() {
            return buffer.empty();
        }
        bool full() {
            return (buffer.size() == size);
        }
        T head() {
            T val = buffer.front();
            return val;
        }
};

iq_rs_buffer_one_input_ref_model* ref_model;

extern "C" void iq_rs_buffer_one_input_model_create(int size, int numwords){
    ref_model = new iq_rs_buffer_one_input_ref_model(size,numwords);
}

extern "C" void iq_rs_buffer_one_input_model_run (
    const svBitVecVal* data,
    svBitVecVal* data_out, 
    svBit push,
    svBit pop,
    svBit* fifo_full,
    svBit* fifo_empty,
    svBit reset_n,
    int numwords
){
    if(!reset_n) {
        ref_model ->reset(numwords);

        T data_outT = ref_model->head();
        for(int i=0; i<numwords; i++) data_out[i] = data_outT[i];
        
        *fifo_full = 1;
        *fifo_empty = 0;

    } else {
        // casting input into vector
        T dataT, data_outT;
        for(int i=0; i<numwords; i++) dataT.push_back(data[i]);

        // intermediate logic
        bool empty = ref_model->empty();
        bool full = ref_model->full();
        bool bypass = push && pop && empty;
        bool push_allowed = push && (!full || (full && pop)) && !bypass;
        bool pop_allowed = pop && (!empty || (empty && push)) && !bypass; 

        if(push_allowed) ref_model->push(dataT); // push if push allowed

        if(pop_allowed) ref_model->pop(); // pop if pop allowed

        // output is head if not bypass or empty
        if(bypass) data_outT = dataT;
        else if(ref_model->empty()) for(int i=0; i<numwords; i++) data_outT.push_back(0);
        else data_outT = ref_model->head();

        // casting outputs
        for(int i=0; i<numwords; i++) data_out[i] = data_outT[i];
        *fifo_full = ref_model->full() ? 1 : 0;
        *fifo_empty = ref_model->empty() ? 1 : 0;
    }
}