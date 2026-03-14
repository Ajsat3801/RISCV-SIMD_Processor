
#include <svdpi.h>
#include <map>
#include <deque>
#include <vector>

typedef std::vector<uint32_t> T;

// Each instance of our FIFO model
class circular_fifo_fwft_ref_model {
    private:
        std::deque<T> buffer;
    public:
        void push(T data) {
            buffer.push_back(data);
        }

        T pop() {
            T val = buffer.front();
            buffer.pop_front();
            return val;
        }

        bool empty(){
            return buffer.empty();
        }
  T peek(){
    T val = buffer.front();
    return val;
  }
};

// Global Registry (The Context Manager)
static std::map<int, circular_fifo_fwft_ref_model*> registry;

extern "C" void circular_fifo_fwft_model_create(int id) {
        registry[id] = new circular_fifo_fwft_ref_model();
    }

extern "C" void circular_fifo_fwft_model_push(int id, const svBitVecVal* data, int numwords) {

        T dataT;
        for(int i = 0;i<numwords; i++){
            dataT.push_back(data[i]);
        }
        registry[id]->push(dataT);
    }

extern "C" void circular_fifo_fwft_model_pop(int id, svBitVecVal* output_buffer, int numwords) {
        if (registry[id]->empty()) for(int i=0; i<numwords; i++) output_buffer[i] = 0;
        else {
            T outputT = registry[id]->pop();
            for(int i = 0; i<numwords;i++) output_buffer[i] = outputT[i];
        }
    }
extern "C" void circular_fifo_fwft_model_peek(int id, svOpenArrayHandle output_buffer, int numwords) {
        if (registry[id]->empty()) for(int i=0; i<numwords; i++) output_buffer[i] = 0;
        else {
            T outputT = registry[id]->peek();
            for(int i = 0; i<numwords;i++) output_buffer[i] = outputT[i];
        }
    }
