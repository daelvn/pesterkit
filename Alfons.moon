tasks:
  compile: => moonc file     for file in wildcard "**.moon"
  clean:   => fs.delete file for file in wildcard "**.lua"
  test:    => sh "moon test2.moon"