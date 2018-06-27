/* ==========================================
    Unity Extensions
    Provides interfaces to custom extensions
    for the Unity Framework.
========================================== */
/* ==========================================
The version of cmock included as part of the Halwayi software package is a 
forked and modified version of the original cmock library. The licensing 
terms that apply to Halwayi also apply to this modified version of cmock. 
Please refer to Halwayi's License for details.
========================================== */


#ifndef __UNITY_EXTENSIONS_H__
#define __UNITY_EXTENSIONS_H__

#include	<CException.h>

/*
	Tells unity that an exception of 'expectedExceptionCode' is expected.
	Helps to write more readable tests with less effort.
*/
void UNITY_EXCEPTION_EXPECTED ( CEXCEPTION_T expectedExceptionCode );

#define	UNITY_EXPECT_EXCEPTION													UNITY_EXCEPTION_EXPECTED
#define	TEST_EXPECT_EXCEPTION													UNITY_EXCEPTION_EXPECTED
#define	TEST_EXCEPTION_EXPECTED													UNITY_EXCEPTION_EXPECTED

#endif
