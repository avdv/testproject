#include <memory>
#include <pthread.h>
#include <sys/wait.h>
#include <sys/time.h>
#include <unordered_map>
#include <semaphore.h>
#include <errno.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>

struct Monitor {
  public:
    pthread_cond_t *cond;
    int *res;
    Monitor(int *res) : res(res) {
        cond = new pthread_cond_t;
        pthread_cond_init(cond, NULL);
    }
    ~Monitor() {
        pthread_cond_destroy(cond);
        delete cond;
    }
};

int scalanative_process_monitor_wait_for_pid(
                                             int *proc_res) {
    const std::shared_ptr<Monitor> monitor = std::make_shared<Monitor>(proc_res);

    return 1;
}
