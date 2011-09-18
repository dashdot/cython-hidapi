from chid cimport *
from libc.stddef cimport wchar_t, size_t
from cpython.unicode cimport PyUnicode_FromUnicode
cdef extern from "ctype.h":
  int wcslen(wchar_t*)

cdef extern from "stdlib.h":
  void free(void* ptr)
  void* malloc(size_t size)

cdef object U(wchar_t *wcs):
  cdef int n = wcslen(wcs)
  return PyUnicode_FromUnicode(<Py_UNICODE*>wcs, n)

cdef class device:
  cdef hid_device *_c_hid
  def __cinit__(self, vendor_id, product_id):
      self._c_hid = hid_open(vendor_id, product_id, NULL)
      if self._c_hid == NULL:
          raise IOError('open failed')

  def write(self, buff):
      '''Accept a list of integers (0-255) and send them to the device'''
      buff = ''.join(map(chr, buff)) # convert to bytes
      cdef unsigned char* cbuff = buff # covert to c string
      return hid_write(self._c_hid, cbuff, len(buff))

  def set_nonblocking(self, v):
      '''Set the nonblocking flag'''
      return hid_set_nonblocking(self._c_hid, v)

  def read(self, max_length):
      '''Return a list of integers (0-255) from the device up to max_length bytes.'''
      cdef unsigned char lbuff[16]
      cdef unsigned char* cbuff
      if max_length <= 16:
          cbuff = lbuff
      else:
          cbuff = <unsigned char *>malloc(max_length)
      n = hid_read(self._c_hid, cbuff, max_length)
      res = []
      for i in range(n):
          res.append(cbuff[i])
      if max_length > 16:
          free(cbuff)
      return res

  def get_manufacturer_string(self):
      cdef wchar_t buff[255]
      cdef int r = hid_get_manufacturer_string(self._c_hid, buff, 255)
      if not r:
          return U(buff)

  def get_product_string(self):
      cdef wchar_t buff[255]
      cdef int r = hid_get_product_string(self._c_hid, buff, 255)
      if not r:
          return U(buff)

  def get_serial_number_string(self):
      cdef wchar_t buff[255]
      cdef int r = hid_get_serial_number_string(self._c_hid, buff, 255)
      if not r:
          return U(buff)

  def error(self):
      return U(<wchar_t*>hid_error(self._c_hid))

      

  