
#include <svdpi.h>
#include <map>
#include <deque>
#include <vector>

typedef std::vector<uint32_t> T;

// Each instance of our FIFO model
class circular_fifo_fwft_ref_model {
    private:
        std::deque<T> buffer;
        int size;
    public:
        circular_fifo_fwft_ref_model(int size){
            this->size = size;
        }
        void push(T data) {
            buffer.push_back(data);
        }
        void pop() {
            buffer.pop_front();
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

circular_fifo_fwft_ref_model* ref_model;

extern "C" void circular_fifo_fwft_model_create(int size){
    ref_model = new circular_fifo_fwft_ref_model(size);
}

extern "C" void circular_fifo_fwft_model_run (
    const svBitVecVal* data,
    svBitVecVal* data_out, 
    svBit push,
    svBit pop,
    svBit* fifo_full,
    svBit* fifo_empty,

    int numwords
){
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