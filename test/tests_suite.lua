package.path = package.path .. ';/app/?.lua;/app/external/?.lua;/app/third-party/?.lua'

local lu = require( 'luaunit' )
local splitN = require( 'splitN' )
local readEntireFile = require( 'readEntireFile' )
local loadConfig = require( 'loadConfig' )
local jwt = require( 'jwt' )
local isTableEmpty = require( 'isTableEmpty' )

TestIsTableEmpty = {}
  function TestIsTableEmpty:testIsFunction()
    lu.assertIsFunction( isTableEmpty )
  end

  function TestIsTableEmpty:testIsEmpty()
    local t = {}
    lu.assertTrue( isTableEmpty( t ) )
  end

  function TestIsTableEmpty:testIsNotEmpty()
    local t = { test = 'test' }
    lu.assertFalse( isTableEmpty( t ) )
  end

-- End of isTableEmpty tests

TestJWT = {}
  function TestJWT:testIsTable()
    lu.assertEquals( type( jwt ), 'table')
  end

  function TestJWT:testIsFunction()
    lu.assertIsFunction( jwt.refresh )
    lu.assertIsFunction( jwt.sign )
    lu.assertIsFunction( jwt.verify )
  end

  -- Some tests here

-- End of jwt tests

TestLoadConfig = {}
  function TestLoadConfig:testIsFunction()
    lu.assertIsFunction( loadConfig )
  end

  function TestLoadConfig:testFileNotExists()
    lu.assertIsNil( loadConfig( 'f' ) )
  end

  function TestLoadConfig:setUp()
    self.fnEmpty = 'test.toml'
    self.fnWithData = 'testWithText.toml'
    os.remove( self.fnEmpty )
    os.remove( self.fnWithData )

    local fd = io.open( self.fnEmpty, 'w' )
    fd:close()

    fd = io.open( self.fnWithData, 'w' )
    fd:write( 'debug=true\n\n[default]\ntest=true' )
    fd:close()
  end
  function TestLoadConfig:testFileIsEmpty()
    lu.assertItemsEquals( { loadConfig( self.fnEmpty ) }, { nil, 'test.toml is an empty config file' } )
    lu.assertItemsEquals( loadConfig( self.fnWithData ), { debug = true, default = { test = true} } )
  end
  function TestLoadConfig:tearDown()
    os.remove( self.fnEmpty )
    os.remove( self.fnWithData )
  end

-- End of loadConfig tests

TestReadEntireFile = {}
  function TestReadEntireFile:testIsFunction()
    lu.assertIsFunction( readEntireFile )
  end

  function TestReadEntireFile:testFileNotExists()
    lu.assertIsNil( readEntireFile( 'f' ) )
  end

  function TestReadEntireFile:testFuncReturnErrorIfFilenameIsEmpty()
    lu.assertError( readEntireFile )
    lu.assertErrorMsgContains( "bad argument #1 to 'open' (string expected, got nil)", readEntireFile )
  end

  function TestReadEntireFile:setUp()
    self.filename = 'test.txt'
    os.remove( self.filename )

    local fd = io.open( self.filename, 'w' )
    fd:write( 'test' )
    fd:close()
  end
  function TestReadEntireFile:testReadFile()
    lu.assertEquals( readEntireFile( self.filename ), 'test' )
    lu.assertNotEquals( readEntireFile( self.filename ), 'test\n' )
  end
  function TestReadEntireFile:tearDown()
    os.remove(self.filename)
  end

-- End of readEntireFile tests

TestSplitN = {}
  function TestSplitN:testIsFunction()
    lu.assertIsFunction( splitN )
  end

  function TestSplitN:testSplitEqualTwo()
    local hello = 'hello world'
    local helloSplitted = splitN( hello, ' ' )
    local line = 'hello every body'
    local lineSplitted = splitN( line, ' ', 2 )

    lu.assertEquals( #helloSplitted, 2 )
    lu.assertEquals( #lineSplitted, 2 )
  end

  function TestSplitN:testTableContainsRightString()
    local hello = 'hello world'
    local helloSplitted = splitN( hello, ' ' )
    local line = 'hello every body'
    local lineSplitted = splitN( line, ' ', 2 )

    lu.assertEquals( helloSplitted[ 1 ], 'hello' )
    lu.assertEquals( helloSplitted[ 2 ], 'world' )
    lu.assertEquals( lineSplitted[ 1 ], 'hello' )
    lu.assertEquals( lineSplitted[ 2 ], 'every body' )
  end

  function TestSplitN:testFuncReturnErrorIfNotString()
    lu.assertError( splitN, 1, ' ' )
    lu.assertErrorMsgContains( "attempt to get length of local 'str' (a number value)", splitN, 1, ' ' )
  end

-- End of splitN tests

os.exit( lu.LuaUnit.run() )