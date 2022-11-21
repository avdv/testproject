
int scalanative_process_monitor_wait_for_pid(
                                             int *proc_res);

int main() {
   int res;
   scalanative_process_monitor_wait_for_pid(&res);
   return 0;
}
