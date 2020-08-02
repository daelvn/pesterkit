tasks:
  compile: => moonc file     for file in wildcard "**.moon"
  clean:   => fs.delete file for file in wildcard "**.lua"