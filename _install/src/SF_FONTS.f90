MODULE SF_FONTS
  implicit none
  private

  public :: bold,underline,highlight,erased
  public :: red,green,yellow,blue
  public :: bold_red,bold_green,bold_yellow,bold_blue
  public :: bg_red,bg_green,bg_yellow,bg_blue

contains

  function bold(text) result(textout)
    character(len=*) :: text
    character(len=8+len(text)) :: textout
    textout=achar(27)//"[1m"//text//achar(27)//"[0m"
  end function bold

  function underline(text) result(textout)
    character(len=*) :: text
    character(len=8+len(text)) :: textout
    textout=achar(27)//"[4m"//text//achar(27)//"[0m"
  end function underline

  function highlight(text) result(textout)
    character(len=*) :: text
    character(len=8+len(text)) :: textout
    textout=achar(27)//"[7m"//text//achar(27)//"[0m"
  end function highlight

  function erased(text) result(textout)
    character(len=*) :: text
    character(len=8+len(text)) :: textout
    textout=achar(27)//"[9m"//text//achar(27)//"[0m"
  end function erased

  function red(text) result(textout)
    character(len=*) :: text
    character(len=9+len(text)) :: textout
    textout=achar(27)//"[91m"//text//achar(27)//"[0m"
  end function red

  function green(text) result(textout)
    character(len=*) :: text
    character(len=9+len(text)) :: textout
    textout=achar(27)//"[92m"//text//achar(27)//"[0m"
  end function green

  function yellow(text) result(textout)
    character(len=*) :: text
    character(len=9+len(text)) :: textout
    textout=achar(27)//"[93m"//text//achar(27)//"[0m"
  end function yellow

  function blue(text) result(textout)
    character(len=*) :: text
    character(len=9+len(text)) :: textout
    textout=achar(27)//"[94m"//text//achar(27)//"[0m"
  end function blue

  function bold_red(text) result(textout)
    character(len=*) :: text
    character(len=11+len(text)) :: textout
    textout=achar(27)//"[1;91m"//text//achar(27)//"[0m"
  end function bold_red

  function bold_green(text) result(textout)
    character(len=*) :: text
    character(len=11+len(text)) :: textout
    textout=achar(27)//"[1;92m"//text//achar(27)//"[0m"
  end function bold_green

  function bold_yellow(text) result(textout)
    character(len=*) :: text
    character(len=11+len(text)) :: textout
    textout=achar(27)//"[1;93m"//text//achar(27)//"[0m"
  end function bold_yellow

  function bold_blue(text) result(textout)
    character(len=*) :: text
    character(len=11+len(text)) :: textout
    textout=achar(27)//"[1;94m"//text//achar(27)//"[0m"
  end function bold_blue

  function bg_red(text) result(textout)
    character(len=*) :: text
    character(len=9+len(text)) :: textout
    textout=achar(27)//"[41m"//text//achar(27)//"[0m"
  end function bg_red

  function bg_green(text) result(textout)
    character(len=*) :: text
    character(len=9+len(text)) :: textout
    textout=achar(27)//"[42m"//text//achar(27)//"[0m"
  end function bg_green

  function bg_yellow(text) result(textout)
    character(len=*) :: text
    character(len=9+len(text)) :: textout
    textout=achar(27)//"[43m"//text//achar(27)//"[0m"
  end function bg_yellow

  function bg_blue(text) result(textout)
    character(len=*) :: text
    character(len=9+len(text)) :: textout
    textout=achar(27)//"[44m"//text//achar(27)//"[0m"
  end function bg_blue

END MODULE SF_FONTS
