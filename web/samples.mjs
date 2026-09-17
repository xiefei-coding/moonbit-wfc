const rows=["~~~~~~~~~~~~~~~~","~~~....~~~~~~~~~","~~..gg..~~~~~~~~","~~.gggg.~~~~~~~~","~~.gg^g..~~~~~~~","~~~.ggg..~~~~~~~","~~~~....~~~~~~~~","~~~~~~~~~~~~~~~~","~~~~~~~~~...~~~~","~~~~~~~~..gg.~~~","~~~~~~~..g^g.~~~","~~~~~~~~.ggg..~~","~~~~~~~~~.....~~","~~~~~~~~~~~~~~~~","~~~~~~...~~~~~~~","~~~~~~~~~~~~~~~~"];
const palette={'~':0xff244f5c|0,'.':0xffd8be83|0,g:0xff8eaf75|0,'^':0xff486449|0};
export const archipelago={name:'群岛',width:16,height:16,pixels:rows.flatMap(row=>Array.from(row,c=>palette[c]))};
export const checker={name:'棋盘',width:4,height:4,pixels:Array.from({length:16},(_,i)=>(i%4+Math.floor(i/4))%2?0xffd8be83|0:0xff244f5c|0)};
