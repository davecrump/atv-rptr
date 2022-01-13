#ifndef __LISTENERS_H__
#define __LISTENERS_H__

void *InputStatusListener(void * arg);
void *SocketListener(void * arg);

extern bool run_repeater;
extern int localGPIO;
extern int inputactive[8];
extern int inputactiveGPIO[8];
extern int inputprioritylevel[8];
extern bool inputStatusChange;
extern int availableinputs;
extern bool StatusScreenOveride;


#endif /* __LISTENERS_H__ */