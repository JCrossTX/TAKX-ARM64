/* Stage-1 ARM64 stand-in for libtakenginejni: the TAK kernel entry points TAKX touches at startup. */
#include <jni.h>
JNIEXPORT void JNICALL Java_com_atakmap_util_ConfigOptions_setOption(JNIEnv *env, jclass cls, jstring key, jstring value) { (void)env; (void)cls; (void)key; (void)value; }
JNIEXPORT jstring JNICALL Java_com_atakmap_util_ConfigOptions_getOption(JNIEnv *env, jclass cls, jstring key, jstring def) { (void)env; (void)cls; (void)key; return def; }
JNIEXPORT void JNICALL Java_com_atakmap_map_EngineLibrary_initJOGL(JNIEnv *env, jclass cls) { (void)env; (void)cls; }
JNIEXPORT void JNICALL Java_com_atakmap_map_EngineLibrary_shutdownImpl(JNIEnv *env, jclass cls) { (void)env; (void)cls; }
