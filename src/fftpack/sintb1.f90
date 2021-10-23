subroutine sintb1 ( n, inc, x, wsave, xh, work, ier )

!*****************************************************************************80
!
!! SINTB1 is an FFTPACK5.1 auxiliary routine.
!
!  License:
!
!    Licensed under the GNU General Public License (GPL).
!    Copyright (C) 1995-2004, Scientific Computing Division,
!    University Corporation for Atmospheric Research
!
!  Modified:
!
!    15 November 2011
!
!  Author:
!
!    Original FORTRAN77 version by Paul Swarztrauber, Richard Valent.
!    FORTRAN90 version by John Burkardt.
!
!  Reference:
!
!    Paul Swarztrauber,
!    Vectorizing the Fast Fourier Transforms,
!    in Parallel Computations,
!    edited by G. Rodrigue,
!    Academic Press, 1982.
!
!    Paul Swarztrauber,
!    Fast Fourier Transform Algorithms for Vector Computers,
!    Parallel Computing, pages 45-63, 1984.
!
!  Parameters:
!
  implicit none

  integer ( kind = 4 ) inc

  real ( kind = 8 ) dsum
  real ( kind = 8 ) fnp1s4
  integer ( kind = 4 ) i
  integer ( kind = 4 ) ier
  integer ( kind = 4 ) ier1
  integer ( kind = 4 ) k
  integer ( kind = 4 ) kc
  integer ( kind = 4 ) lnsv
  integer ( kind = 4 ) lnwk
  integer ( kind = 4 ) lnxh
  integer ( kind = 4 ) modn
  integer ( kind = 4 ) n
  integer ( kind = 4 ) np1
  integer ( kind = 4 ) ns2
  real ( kind = 8 ) srt3s2
  real ( kind = 8 ) t1
  real ( kind = 8 ) t2
  real ( kind = 8 ) work(*)
  real ( kind = 8 ) wsave(*)
  real ( kind = 8 ) x(inc,*)
  real ( kind = 8 ) xh(*)
  real ( kind = 8 ) xhold

      ier = 0
      if (n-2) 200,102,103
  102 srt3s2 = sqrt( 3.0D+00 ) / 2.0D+00
      xhold = srt3s2*(x(1,1)+x(1,2))
      x(1,2) = srt3s2*(x(1,1)-x(1,2))
      x(1,1) = xhold
      return

  103 np1 = n+1
      ns2 = n/2
      do 104 k=1,ns2
         kc = np1-k
         t1 = x(1,k)-x(1,kc)
         t2 = wsave(k)*(x(1,k)+x(1,kc))
         xh(k+1) = t1+t2
         xh(kc+1) = t2-t1
  104 continue
      modn = mod(n,2)
      if (modn == 0) go to 124
      xh(ns2+2) =  4.0D+00 * x(1,ns2+1)
  124 xh(1) = 0.0D+00
      lnxh = np1
      lnsv = np1 + int(log( real ( np1, kind = 8 ))/log( 2.0D+00 )) + 4
      lnwk = np1

      call rfft1f(np1,1,xh,lnxh,wsave(ns2+1),lnsv,work,lnwk,ier1)

      if (ier1 /= 0) then
        ier = 20
        call xerfft ('sintb1',-5)
        return
      end if

      if(mod(np1,2) /= 0) go to 30
      xh(np1) = xh(np1)+xh(np1)
 30   fnp1s4 = real ( np1, kind = 8 ) / 4.0D+00
         x(1,1) = fnp1s4*xh(1)
         dsum = x(1,1)
      do i=3,n,2
            x(1,i-1) = fnp1s4*xh(i)
            dsum = dsum+fnp1s4*xh(i-1)
            x(1,i) = dsum
      end do

      if ( modn == 0 ) then
         x(1,n) = fnp1s4*xh(n+1)
      end if

  200 continue

  return
end
