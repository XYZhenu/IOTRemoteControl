project_path=$(cd `dirname $0`; pwd)
echo "Place enter the number you want do. 
1:update ZLMediaKit 
2:run in simulator
3:run in iphone"


derivedDataPath=$project_path/ZLMediaKit/build/derivedData
desLibPath=$derivedDataPath/ArchiveIntermediates/ALL_BUILD/IntermediateBuildFilesPath/UninstalledProducts
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
xcodebuild archive -project ${project_name} -scheme ALL_BUILD -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 11' -derivedDataPath $derivedDataPath
cmake .. -G Xcode -DCMAKE_TOOLCHAIN_FILE=../cmake/ios.toolchain.cmake  -DPLATFORM=SIMULATOR
xcodebuild archive -project ${project_name} -scheme ALL_BUILD -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 11' -derivedDataPath $derivedDataPath

# sdks_path=${project_path}/IOSPlayer/SDKs
# rm -rf $sdks_path
# mkdir $sdks_path


# lipo -create file.a file.b -output file.c

else

echo "end"

fi