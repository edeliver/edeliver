guard 'minitest', :notify => false do
  watch(%r|^test/(.*)_test\.rb|)
  watch(%r|^libexec/(.*)([^/]+)|)     { |m| "test/#{m[1]}#{m[2]}_test.rb" }
  watch(%r|^test/test_helper\.rb|)    { "test" }
  watch(%r|^man/deliver\.ronn|)       { `man/build` }
end
