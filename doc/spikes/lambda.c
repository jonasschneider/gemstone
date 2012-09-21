#include <stdio.h>

int main() {
    long long c;

    register long rsp asm ("rsp");

    printf("starting\n");

    //goto afterlambda;
    
    asm("jmp afterlambda");
    asm("mylambda:");
    printf("RSP in lambda: %lx\n", rsp);
//mylambda:
    
    // set up stack frame
    asm ("push %rbp");
    asm ("mov %rsp, %rbp");

    asm ("mov 0x10(%%rsp), %0;\n\t"
         :"=r"(c));        /* output */
    printf("in lambda, c=0x%llx, c=%lld\n", c, c);

    // pop stack frame
    asm ("mov %rbp, %rsp");
    asm ("pop %rbp");

    printf("RSP before ret: %lx\n", rsp);
    asm("ret");

    asm("afterlambda:");

    //printf("a=%lld, b=%lld\n",a,b);


    //printf("\n");

    //asm("call mylambda");

    //printf("call done\n");

    printf("RSP in main: %lx\n", rsp);

    //printf("a=%lld, b=%lld\n",a,b);  

    asm ("push $0x10\n\t"
         "call mylambda\n\t"
         "add $8, %rsp"
         );

    printf("RSP after call: %lx\n", rsp);
    return 0;
}