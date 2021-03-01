project_path=$(cd `dirname $0`; pwd)
echo "Place enter the number you want do. 
1:update ZLMediaKit 
2:run in simulator
3:run in iphone"

cd ZLMediaKit

read number

if [ $number == 1 ]; then
#git pull
#git submodule update
rm -rf build
mkdir build
cd build
cmake .. -G Xcode -DCMAKE_TOOLCHAIN_FILE=../cmake/ios.toolchain.cmake  -DPLATFORM=OS
project_name=$(ls ./ | grep '.xcodeproj')
xcodebuild archive -project ${project_name} -scheme ALL_BUILD -configuration Debug
cmake .. -G Xcode -DCMAKE_TOOLCHAIN_FILE=../cmake/ios.toolchain.cmake  -DPLATFORM=SIMULATOR
xcodebuild archive -project ${project_name} -scheme ALL_BUILD -configuration Debug
else

echo "end"

fi