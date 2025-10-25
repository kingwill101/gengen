---
title: 'The Fortran Programming Language'
date: 2015-11-26T08:40:00.001-08:00
draft: false
aliases: [ "/2015/11/the-fortran-programming-language.html" ]
tags : [programming, computer programming, fortran, history]
---

Written September 5, 2013  
  
  

[![](https://encrypted-tbn3.gstatic.com/images?q=tbn:ANd9GcT_AV7_lHiKzyFFDUw2bu6lkMuEO7TNscubhCdz_UZMHgYez11Krg)](https://encrypted-tbn3.gstatic.com/images?q=tbn:ANd9GcT_AV7_lHiKzyFFDUw2bu6lkMuEO7TNscubhCdz_UZMHgYez11Krg)

  
  
One of the oldest programming languages, the Fortran programming language known mainly for its strength in numeric and scientific computation, was developed in the 1950′s and first published in 1957 by IBM in San Jose California as the first known high level programming language. Fortran came about at a time where programmers only had the opportunity to create programs using assembly and machine code which came with several downfalls such as it was:  

*   long and tedius to write
*   quite bug prone
*   very hard to debug
*   code that was written was architecture dependent thus not portable

  
now with the rise of Fortran, programers were able to write code at a much faster rate giving the programmer a lot more time to focus on solving problems than on the code being written. It was a true innovation in its day, being credited with the creation of the branch of computer science known today as the compiler theory.  
Over the years Fortran has seen significant changes to its dialect after programmers over time saw the need to modify it to better suite their needs, which led to the American Association releasing its first standard of a Programming Language in 1966 which came to being known as the FORTRAN 66.  
  
Significant Language Features  
  

*   Simple to learn – when FORTRAN was designed one of its objectives were to write a language that was easy to learn and understand.
*   Machine Independent – allows for easy transportation of a program from one machine to another.
*   More natural ways to express mathematical functions – FORTRAN permits even severely complex mathematical functions to be expressed similarly to regular algebraic notation.
*   Problem orientated language
*   Remains close to and exploits the available hardware
*   Efficient execution – there is only an approximate 20% decrease in efficiency as compared to assembly/machine code.
*   Ability to control storage allocation -programmers were able to easily control the allocation of storage (although this is considered to be a dangerous practice today, it was quite important some time ago due to limited memory.
*   More freedom in code layout – unlike assembly/machine language, code does not need to be laid out in rigidly defined columns, (though it still must remain within the parameters of the FORTRAN source code form).

Sample Hello world code written in fortran  
  
```
program hello  
print *, "Hello World!"  
end program hello  
  ``` 
**sources:**  

*   [Wikipedia](http://en.wikipedia.org/wiki/Fortran)
*   [Umich](http://groups.engin.umd.umich.edu/CIS/course.des/cis400/fortran/fortran.html)