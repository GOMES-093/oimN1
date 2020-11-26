class Key{
  boolean[] pa = new boolean[2048];// rotation pattern
  boolean[] mp = new boolean[2048];// map of puzzle
  byte[] tn = new byte[8];// number of try
  byte[] hp = new byte[8];// position of hole
  short of =(short)(random(0, 2048));// offset of read pattern
  short in =(short)(random(0, 1024));// initial state
  byte sl=byte(random(8, 16));// slip force (infinite move limitation)
  int pt=of;// pointer for reading pattern 
  int ir=(in&0x300)>>7;// initial direction 
  int ix=(in&0xF0)>>4;
  int iy=in&0xF;
  
  Key(){
    this(32);
  }
  Key(int RATE){
    generateKey(RATE);
  }
  Key generateKey(int rate){
    boolean success=false;
    int attempts = 0;
    while(!success&&attempts++<100){
      println("generating key... (attempt "+attempts+"/100)");
      generateValues();
      generateMap(rate);
      generatePattern();
      success=generateHoles();
    }
    if(!success)
    {
      print("couldn't generate key. please check wall spawning rate.");
      return null;
    }
    return this;
  }
  
  void generateValues() {
    of =(short)(random(0, 2048));// offset of read pattern
    in =(short)(random(0, 1024));// initial state
    sl=byte(random(8, 16));// slip force (infinite move limitation)
    pt=of;// pointer for reading pattern 
    ir=(in&0x300)>>7;// initial direction 
    ix=(in&0xF0)>>4;
    iy=in&0xF;
    for (int i=0; i<tn.length; i++) {//Times of tries on each layer
      tn[i]=byte(random(0, 256));
    }
  }
  void generateMap(int rate){
    for (int i=0; i<mp.length; i++) {//map init
      mp[i]=(byte(random(0, 256))&0xFF)<rate;
    }
  }
  void generatePattern(){
    for (int i=0; i<pa.length; i++) {//pattern l:r=1:1
      pa[i]=random(1)>=.5;
    }
  }
  boolean generateHoles() {// makeHoles
    int rx=ix, ry=iy, r=ir; // state of explorer
    for (int l=0; l<tn.length; l++) {// run on 8 layers
      if(isSuffocated(rx,ry,l))return false;
      int tr=tn[l]&0xFF;
      for (int t=0; t<tr; t++) {// try specified times
        r=l(pa[pt]?r+1:r-1, 4);// rotate as pattern says
        for (int s=0; s<sl; s++) {
          if (r==0) { // up
            if (!isWall(rx, l(ry-1), l)) ry=l(ry-1);
            else break;
          }
          if (r==2) { // down
            if (!isWall(rx, l(ry+1), l)) ry=l(ry+1);
            else break;
          }
          if (r==1) { // right
            if (!isWall(l(rx+1), ry, l)) rx=l(rx+1);
            else break;
          }
          if (r==3) { // left
            if (!isWall(l(rx-1), ry, l)) rx=l(rx-1);
            else break;
          }
        }
        if (++pt==2048)pt=0; // incriment pointer and loop
      }
      hp[l]=byte((ry<<4)+rx);// set hole position
    }
    return true;
  }
  
  boolean solvePuzzle() {// check key pair
    pt = of;//set pointer;
    int rx=ix, ry=iy, r=ir; // state of explorer
    for (int l=0; l<tn.length; l++) {// run on 8 layers
      if(isSuffocated(rx,ry,l))return false;// suffocation cannot be happened
      int tr=tn[l]&0xFF;
      for (int t=0; t<tr; t++) {// try specified times
        r=l(pa[pt]?r+1:r-1, 4);// rotate as pattern says
        for (int s=0; s<sl; s++) {
          if (r==0) { // up
            if (!isWall(rx, l(ry-1), l)) ry=l(ry-1);
            else break;
          }
          if (r==2) { // down
            if (!isWall(rx, l(ry+1), l)) ry=l(ry+1);
            else break;
          }
          if (r==1) { // right
            if (!isWall(l(rx+1), ry, l)) rx=l(rx+1);
            else break;
          }
          if (r==3) { // left
            if (!isWall(l(rx-1), ry, l)) rx=l(rx-1);
            else break;
          }
        }
        if (++pt==2048)pt=0; // incriment pointer and loop
      }
      if(!(hp[l]==byte((ry<<4)+rx)))return false;// check hole position
    }
    return true;
  }
  
  String getPublicKey(){
    // Let's export these to file
    return b2s(pa);
  }
  String getPrivateKey(){
    // I think json is better
    String map=b2s(mp);
    String hol=b2s(hp,2);
    String tri=b2s(tn,2);
    String off=hex(of,3);
    String ini=hex((in&0xFF)+(ir<<8),3);
    String sli=hex(sl,1);
    return map+hol+tri+off+ini+sli;
  }
  void printResult(){
    println("==public==");
    println("pattern: ");
    int[] tmp=b2i(pa);
    int cnt=0;
    for(int m:tmp){
      print(hex(m,8));
      print(++cnt%4==0?"\n":"");
    }
    println("==private==");
    println("map: ");
    int[] tmq=b2i(mp);
    int cnu=0;
    for(int m:tmq){
      print(hex(m,8));
      print(++cnu%4==0?"\n":"");
    }
    print("holes: ");
    for (byte h : hp) {
      print(hex(h,2));
    }println();
    print("tries: ");
    for (byte t : tn) {
      print(hex(t,2));
    }println();
    print("offset: ");
    println(hex(of,3));
    print("init: ");
    println(hex((in&0xFF)+(ir<<8),3));
    print("slip: ");
    println(hex(sl,1));
  }
  
  private int l(int in, int mx) {
    while (in>=mx)in-=mx;
    while (in<0)in+=mx;
    return in;
  }
  private int l(int in) {
    return l(in, 16);
  }
  private boolean isWall(int x, int y, int l) {
    return mp[(l<<8)+(y<<4)+x];
  }
  private boolean isSuffocated(int x, int y, int l) {
    int la=l<<8;
    if(mp[la+(l(y-1)<<4)+x]&&mp[la+(l(y+1)<<4)+x]&&mp[la+(y<<4)+l(x-1)]&&mp[la+(y<<4)+l(x+1)]){// if surrounded by walls
      return true;
    }
    return false;
  }
  private int[] b2i(boolean[] b){
    int[] tmp=new int[64];
    for(int i=0;i<64;i++){
      int tmi=0;
      for(int j=0;j<4;j++){
        for(int l=0;l<8;l++){
          tmi+=b[(i<<2)+j+(l<<8)]?1<<(l+j*8):0;
        }
      }
      tmp[i]=tmi;
    }
    return tmp;
  }
  private String i2s(int[] il){
    String tmp="";
    for(int i:il){
      tmp+=hex(i,8);
    }
    return tmp;
  }
  private String b2s(boolean[] b){
    return i2s(b2i(b));
  }
  private String b2s(byte[] bl,int n){
    String tmp="";
    for(byte b:bl){
      tmp+=hex(b&0xFF,2);
    }
    return tmp;
  }
}

void setup(){
  Key test = new Key(96);// generate key
  test.printResult();// print details
  
  // brute-force demo or something
  int attempt=1;
  int MAXATTEMPT=10000000;
  test.generatePattern();// invalidate
  if(test.solvePuzzle())print("Valid!");else print("Invalid.");
  println("random pattern regeneration attack demo");
  test.generatePattern();// invalidate
  while(!test.solvePuzzle()&&attempt++<MAXATTEMPT){
    if(attempt%100000==0)println("random brute-force attempt: "+attempt+"/"+MAXATTEMPT);
    test.generatePattern();
  }
  if(test.solvePuzzle())print("Valid!");else print("Invalid.");
}
