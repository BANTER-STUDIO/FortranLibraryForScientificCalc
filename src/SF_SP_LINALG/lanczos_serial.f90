!---------------------------------------------------------------------
!Purpose: use plain lanczos to get the groundstate energy
!---------------------------------------------------------------------
subroutine lanczos_eigh_d(MatVec,Ndim,Nitermax,Egs,Vect,iverbose,threshold,ncheck)
  interface
     subroutine MatVec(Nloc,vin,vout)
       integer                 :: Nloc
       real(8),dimension(Nloc) :: vin
       real(8),dimension(Nloc) :: vout
     end subroutine MatVec
  end interface
  integer                              :: Ndim
  integer                              :: Nitermax
  real(8)                              :: egs
  real(8),dimension(Ndim)              :: vect
  real(8),optional                     :: threshold
  integer,optional                     :: ncheck
  logical,optional                     :: iverbose
  !
  real(8),dimension(Ndim)              :: vin,vout
  integer                              :: iter,nlanc
  real(8),dimension(Nitermax+1)        :: alanc,blanc
  real(8),dimension(Nitermax,Nitermax) :: Z
  real(8),dimension(Nitermax)          :: diag,subdiag,esave
  real(8)                              :: a_,b_
  real(8)                              :: norm,diff
  integer                              :: i,ierr
  !
  if(present(iverbose))verb=iverbose
  if(present(threshold))threshold_=threshold
  if(present(ncheck))ncheck_=ncheck
  !
  norm=dot_product(vect,vect)
  if(norm==0d0)then
     call random_seed(size=nrandom)
     if(allocated(seed_random))deallocate(seed_random)
     allocate(seed_random(nrandom))
     seed_random=1234567
     call random_seed(put=seed_random)
     call random_number(vect)
     vect=vect/sqrt(dot_product(vect,vect))
     if(verb)write(*,*)"LANCZOS_EIGH_D: random initial vector generated:"
  endif
  !
  !============= LANCZOS LOOP =====================
  !
  vin = vect
  vout= 0.d0
  alanc=0.d0
  blanc=0.d0
  nlanc=0
  !
  lanc_loop: do iter=1,Nitermax
     !
     if(verb)then
        print*,""
        write(*,*)"Lanczos iteration:",iter
     endif
     !
     call lanczos_iteration_d(MatVec,iter,vin,vout,a_,b_)
     if(abs(b_)<threshold_)exit lanc_loop
     !
     nlanc=nlanc+1
     !
     alanc(iter) = a_ ; blanc(iter+1) = b_
     !
     diag    = 0d0
     subdiag = 0.d0
     Z       = eye(Nlanc)
     diag(1:Nlanc)    = alanc(1:Nlanc)
     subdiag(2:Nlanc) = blanc(2:Nlanc)
     call tql2(Nlanc,diag,subdiag,Z,ierr)
     !
     if(verb)then
        print *,'---> lowest eigenvalue  <---'
        write(*,*)"E_lowest    = ",diag(1)
        open(10,file="lanc_eigenvals.dat")
        do i=1,Nlanc
           write(10,*)i,diag(i)
        enddo
        close(10)
     endif
     !
     if(nlanc >= Ncheck_)then
        esave(nlanc-(Ncheck_-1))=diag(1)
        if(nlanc >= (Ncheck_+1))then
           diff=esave(Nlanc-(Ncheck_-1))-esave(Nlanc-(Ncheck_-1)-1)
           if(verb)write(*,*)'test deltaE = ',diff
           if(abs(diff).le.threshold_)exit lanc_loop
        endif
     endif
     !
  enddo lanc_loop
  if(verb)write(*,*)'lanczos deltaE  = ',diff
  if(nlanc==nitermax)print*,"LANCZOS_SIMPLE: reach Nitermax"
  !
  !============== END LANCZOS LOOP ======================
  !
  diag    = 0d0
  subdiag = 0.d0
  Z       = eye(Nlanc)
  diag(1:Nlanc)    = alanc(1:Nlanc)
  subdiag(2:Nlanc) = blanc(2:Nlanc)
  call tql2(Nlanc,diag,subdiag,Z,ierr)
  !
  !Get the Eigenvalues:
  egs = diag(1)
  !
  !Get the Eigenvector:
  vin =vect
  vout=0.d0
  vect=0.d0
  do iter=1,Nlanc
     call lanczos_iteration_d(MatVec,iter,vin,vout,alanc(iter),blanc(iter))
     vect = vect + vin*Z(iter,1)
  end do
  norm=sqrt(dot_product(vect,vect))
  vect=vect/norm
  !
  Nitermax=Nlanc
  !
end subroutine lanczos_eigh_d

subroutine lanczos_eigh_c(MatVec,Ndim,Nitermax,Egs,Vect,iverbose,threshold,ncheck)
  interface
     subroutine MatVec(Nloc,vin,vout)
       integer                    :: Nloc
       complex(8),dimension(Nloc) :: vin
       complex(8),dimension(Nloc) :: vout
     end subroutine MatVec
  end interface
  integer                              :: Ndim
  integer                              :: Nitermax
  real(8)                              :: egs
  complex(8),dimension(Ndim)           :: vect
  real(8),optional                     :: threshold
  integer,optional                     :: ncheck
  logical,optional                     :: iverbose
  !
  complex(8),dimension(Ndim)           :: vin,vout
  integer                              :: iter,nlanc
  real(8),dimension(Nitermax+1)        :: alanc,blanc
  real(8),dimension(Nitermax,Nitermax) :: Z
  real(8),dimension(Nitermax)          :: diag,subdiag,esave
  real(8)                              :: a_,b_
  real(8)                              :: norm,diff,ran(2)
  integer                              :: i,ierr
  !
  if(present(iverbose))verb=iverbose
  if(present(threshold))threshold_=threshold
  if(present(ncheck))ncheck_=ncheck
  !
  norm=dot_product(vect,vect)
  if(norm==0d0)then
     call random_seed(size=nrandom)
     if(allocated(seed_random))deallocate(seed_random)
     allocate(seed_random(nrandom))
     seed_random=1234567
     call random_seed(put=seed_random)
     do i=1,Ndim
        call random_number(ran)
        vect(i)=dcmplx(ran(1),ran(2))
     enddo
     vect=vect/sqrt(dot_product(vect,vect))
     if(verb)write(*,*)"LANCZOS_EIGH_C: random initial vector generated:"
  endif
  !
  !============= LANCZOS LOOP =====================
  !
  vin = vect
  vout= zero
  alanc=0.d0
  blanc=0.d0
  nlanc=0
  !
  lanc_loop: do iter=1,Nitermax
     !
     if(verb)then
        print*,""
        write(*,*)"Lanczos iteration:",iter
     endif
     !
     call lanczos_iteration_c(MatVec,iter,vin,vout,a_,b_)
     if(abs(b_)<threshold_)exit lanc_loop
     !
     nlanc=nlanc+1
     !
     alanc(iter) = a_ ; blanc(iter+1) = b_
     !
     diag    = 0d0
     subdiag = 0d0
     Z       = eye(Nlanc)
     diag(1:Nlanc)    = alanc(1:Nlanc)
     subdiag(2:Nlanc) = blanc(2:Nlanc)
     call tql2(Nlanc,diag,subdiag,Z,ierr)
     !
     if(verb)then
        print *,'---> lowest eigenvalue  <---'
        write(*,*)"E_lowest    = ",diag(1)
        open(10,file="lanc_eigenvals.dat")
        do i=1,Nlanc
           write(10,*)i,diag(i)
        enddo
        close(10)
     endif
     !
     if(nlanc >= Ncheck_)then
        esave(nlanc-(Ncheck_-1))=diag(1)
        if(nlanc >= (Ncheck_+1))then
           diff=esave(Nlanc-(Ncheck_-1))-esave(Nlanc-(Ncheck_-1)-1)
           if(verb)write(*,*)'test deltaE = ',diff
           if(abs(diff).le.threshold_)exit lanc_loop
        endif
     endif
     !
  enddo lanc_loop
  if(verb)write(*,*)'lanczos deltaE  = ',diff
  if(nlanc==nitermax)write(*,"(A)")"LANCZOS_EIGH_D: reach Nitermax"
  !
  !============== END LANCZOS LOOP ======================
  !
  diag    = 0d0
  subdiag = 0.d0
  Z       = eye(Nlanc)
  diag(1:Nlanc)    = alanc(1:Nlanc)
  subdiag(2:Nlanc) = blanc(2:Nlanc)
  call tql2(Nlanc,diag,subdiag,Z,ierr)
  !
  !Get the Eigenvalues:
  egs = diag(1)
  !
  !Get the Eigenvector:
  vin =vect
  vout=0.d0
  vect=0.d0
  do iter=1,Nlanc
     call lanczos_iteration_c(MatVec,iter,vin,vout,alanc(iter),blanc(iter))
     vect = vect + vin*Z(iter,1)
  end do
  norm=sqrt(dot_product(vect,vect))
  vect=vect/norm
  !
  Nitermax=Nlanc
  !
end subroutine lanczos_eigh_c











!---------------------------------------------------------------------
!Purpose: use simple Lanczos to tri-diagonalize a matrix H (defined 
! in the H*v function).
!---------------------------------------------------------------------
subroutine lanczos_tridiag_d(MatVec,vin,alanc,blanc,threshold)
  interface
     subroutine MatVec(Nloc,vin,vout)
       integer                 :: Nloc
       real(8),dimension(Nloc) :: vin
       real(8),dimension(Nloc) :: vout
     end subroutine MatVec
  end interface
  real(8),dimension(:),intent(inout)           :: vin
  real(8),dimension(size(vin))                 :: vout
  real(8),dimension(:),intent(inout)           :: alanc
  real(8),dimension(size(alanc)),intent(inout) :: blanc
  integer                                      :: Nitermax
  integer                                      :: iter
  real(8)                                      :: a_,b_
  real(8),optional                             :: threshold
  !
  if(present(threshold))threshold_=threshold
  !
  Nitermax = size(alanc)
  a_=0d0
  b_=0d0
  vout=0d0
  do iter=1,Nitermax
     call lanczos_iteration_d(MatVec,iter,vin,vout,a_,b_)
     alanc(iter)=a_
     if(abs(b_)<threshold_)exit
     if(iter<nitermax)blanc(iter+1)=b_
  enddo
  if(iter==nitermax)write(*,"(A)")"LANCZOS_TRIDIAG_D: reach Nitermax"
end subroutine lanczos_tridiag_d

subroutine lanczos_tridiag_c(MatVec,vin,alanc,blanc,threshold)
  interface
     subroutine MatVec(Nloc,vin,vout)
       integer                    :: Nloc
       complex(8),dimension(Nloc) :: vin
       complex(8),dimension(Nloc) :: vout
     end subroutine MatVec
  end interface
  complex(8),dimension(:),intent(inout)        :: vin
  complex(8),dimension(size(vin))              :: vout
  real(8),dimension(:),intent(inout)           :: alanc
  real(8),dimension(size(alanc)),intent(inout) :: blanc
  integer                                      :: Nitermax
  integer                                      :: iter
  real(8)                                      :: a_,b_
  real(8),optional                             :: threshold
  !
  if(present(threshold))threshold_=threshold
  !
  Nitermax = size(alanc)
  a_=0d0
  b_=0d0
  vout=zero
  do iter=1,Nitermax
     call lanczos_iteration_c(MatVec,iter,vin,vout,a_,b_)
     alanc(iter)=a_
     if(abs(b_)<threshold_)exit
     if(iter<nitermax)blanc(iter+1)=b_
  enddo
  if(iter==nitermax)print*,"LANCZOS_TRIDIAG_C: reach Nitermax"
end subroutine lanczos_tridiag_c








!---------------------------------------------------------------------
!Purpose: plain homebrew lanczos iteration (no orthogonalization)
!note: the a,b variables are real, even in the complex matrix case
!to understand why check out the Gollub-Van Loan textbook.
!a it is easy: hermiticity->diag\in\RRR
!b: is fixed by requiring |b|^2 = <v,v> thus you can only fix the 
!the absolute value. A lemma shows that the phase can be chosen 
!identically zero
!---------------------------------------------------------------------
subroutine lanczos_iteration_d(MatVec,iter,vin,vout,a,b)
  interface
     subroutine MatVec(Nloc,vin,vout)
       integer                 :: Nloc
       real(8),dimension(Nloc) :: vin
       real(8),dimension(Nloc) :: vout
     end subroutine MatVec
  end interface
  integer                                    :: iter
  real(8),dimension(:),intent(inout)         :: vin
  real(8),dimension(size(vin)),intent(inout) :: vout
  real(8),dimension(size(vin))               :: tmp
  real(8),intent(inout)                      :: a,b
  integer                                    :: ndim
  real(8)                                    :: norm
  !
  ndim=size(vin)
  !
  if(iter==1)then
     norm=sqrt(dot_product(vin,vin))
     if(norm==0.d0)stop "LANCZOS_ITERATION_D: norm =0!!"
     vin=vin/norm
     b=0d0
  end if
  !
  call MatVec(ndim,vin,tmp)
  !
  tmp = tmp-b*vout
  a   = dot_product(vin,tmp)
  tmp = tmp-a*vin
  b   = sqrt(dot_product(tmp,tmp))
  vout= vin
  vin = tmp/b
end subroutine lanczos_iteration_d

subroutine lanczos_iteration_c(MatVec,iter,vin,vout,a,b)
  interface
     subroutine MatVec(Nloc,vin,vout)
       integer                    :: Nloc
       complex(8),dimension(Nloc) :: vin
       complex(8),dimension(Nloc) :: vout
     end subroutine MatVec
  end interface
  integer                                       :: iter
  complex(8),dimension(:),intent(inout)         :: vin
  complex(8),dimension(size(vin)),intent(inout) :: vout
  complex(8),dimension(size(vin))               :: tmp
  real(8),intent(inout)                         :: a,b
  integer                                       :: ndim
  real(8)                                       :: norm
  !
  ndim=size(vin)
  !
  if(iter==1)then
     norm=sqrt(dot_product(vin,vin))
     if(norm==0.d0)stop "LANCZOS_ITERATION_C: norm =0!!"
     vin=vin/norm
     b=0d0
  end if
  !
  call MatVec(ndim,vin,tmp)
  !
  tmp = tmp-b*vout
  a   = dot_product(vin,tmp)
  tmp = tmp-a*vin
  b   = sqrt(dot_product(tmp,tmp))
  vout= vin
  vin = tmp/b
end subroutine lanczos_iteration_c
