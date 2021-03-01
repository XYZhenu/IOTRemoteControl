project_path=$(cd `dirname $0`; pwd)
echo "Place enter the number you want do. 
1:build iphone
2:build simulator
3:merge to fat"


derivedDataPath=$project_path/ZLMediaKit/build/derivedData
desLibPath=$derivedDataPath/ArchiveIntermediates/ALL_BUILD/IntermediateBuildFilesPath/UninstalledProducts
productPath=$project_path/IOSPlayer/SDKs

read number
#git pull
#git submodule update

if [ $number == 1 ]; then
cd $project_path/ZLMediaKit
# rm -rf build
# mkdir build
cd build
cmake .. -G Xcode -DCMAKE_TOOLCHAIN_FILE=../cmake/ios.toolchain.cmake  -DPLATFORM=OS
project_name=$(ls ./ | grep '.xcodeproj')
xcodebuild archive -project ${project_name} -scheme ALL_BUILD -configuration Debug -destination 'platform=iOS,name=xo' -derivedDataPath $derivedDataPath
rm -rf $productPath/iphoneos
cp -r $desLibPath/iphoneos $productPath

elif [ $number == 2 ]; then

cd $project_path/ZLMediaKit
rm -rf build
mkdir build
cd build
cmake .. -G Xcode -DCMAKE_TOOLCHAIN_FILE=../cmake/ios.toolchain.cmake  -DPLATFORM=SIMULATOR64
project_name=$(ls ./ | grep '.xcodeproj')
xcodebuild archive -project ${project_name} -scheme ALL_BUILD -configuration Debug -derivedDataPath $derivedDataPath
rm -rf $productPath/iphonesimulator
cp -r $desLibPath/iphonesimulator $productPath

elif [ $number == 3 ]; then

rm -rf $productPath/iphoneuniversal
mkdir $productPath/iphoneuniversal

for file in $productPath/iphoneos/*
do
    filename=${file##*/}
    lipo -create $file $productPath/iphonesimulator/$filename -output $productPath/iphoneuniversal/$filename
done
ln -s $productPath/iphoneuniversal $productPath/iphone
else

echo "end"

fi