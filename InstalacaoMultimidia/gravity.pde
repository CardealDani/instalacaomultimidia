import processing.serial.*;
import processing.sound.*;

// --- CONFIGURAÇÃO ---
boolean usarArduino = false; 
Serial minhaPorta;

// --- ASSETS ---
PImage imgIdle;            
PImage[] animJump = new PImage[8]; 
PImage[] fundos = new PImage[7]; 
PImage imgChao;   
PImage imgFlag;   
boolean imagensCarregadas = false;

// Ajuste Visual
int ajusteY = 0; 
int charWidth = 40;
int charHeight = 60;
int tamanhoBloco = 50; 

// --- SOM ---
SinOsc somMotor;        
TriOsc somVitoria;      
WhiteNoise somFalha;    
Env envelope;           

// --- JOGO ---
int fase = 1;
int maxPulos = 3; 
int pulosRestantes;
// Novos Estados: "CAINDO_BURACO", "BATENDO_TETO"
String estadoJogo = "CALIBRANDO"; 

// --- FÍSICA ---
float playerX, playerY;
float velocidadeX = 5;
float velocidadeY = 0;
float forcaPulo = -13; 
float gravidade = 0.5; 

// --- INPUTS ---
float inputGravidade = 0; 
boolean inputPulo = false; 
boolean puloAnterior = false; 

// --- AMBIENTE ---
float chaoY = 300;
float tetoY = 0;
float fimDoPerigo = 0;
ArrayList<PVector> buracos = new ArrayList<PVector>();
char ultimoComandoLed = ' '; 

void setup() {
  size(800, 400);
  
  try {
    imgIdle = loadImage("idle.png");
    imgIdle.resize(charWidth, charHeight); 
    
    for (int i = 0; i < animJump.length; i++) {
      animJump[i] = loadImage("jump" + i + ".png");
      animJump[i].resize(charWidth, charHeight);
    }

    for (int i = 0; i < fundos.length; i++) {
      fundos[i] = loadImage("bg" + i + ".png");
      fundos[i].resize(width, height);
    }
    
    imgChao = loadImage("ground.png");
    imgChao.resize(tamanhoBloco, tamanhoBloco);
    
    imgFlag = loadImage("flag.png");
    imgFlag.resize(40, 60);

    imagensCarregadas = true;
  } catch (Exception e) {
    imagensCarregadas = false;
    println("Erro ao carregar imagens. Verifique a pasta data.");
  }

  somMotor = new SinOsc(this); somMotor.play(); somMotor.amp(0.0);
  somVitoria = new TriOsc(this); somFalha = new WhiteNoise(this); envelope = new Env(this); 
  
  if (usarArduino) {
    try {
      minhaPorta = new Serial(this, Serial.list()[0], 9600); 
      minhaPorta.bufferUntil('\n'); 
    } catch (Exception e) {
      usarArduino = false;
    }
  }
  iniciarNovaFase();
}

void draw() {
  // 1. DESENHAR FUNDO
  if (imagensCarregadas && fundos.length > 0) {
    int idx = (fase - 1) % fundos.length;
    imageMode(CORNER); 
    image(fundos[idx], 0, 0);
    imageMode(CENTER); 
  } else {
    background(30);
  }

  lerInputs();
  if (usarArduino) atualizarLedsArduino();

  // Audio
  float freq = map(gravidade, 0.3, 1.8, 300, 60);
  somMotor.freq(freq);
  if (estadoJogo.equals("CALIBRANDO")) somMotor.amp(0.05); 
  else if (estadoJogo.equals("PULANDO")) somMotor.amp(0.08); 
  else somMotor.amp(0.0); 

  // Lógica
  if (estadoJogo.equals("CALIBRANDO")) {
    if (usarArduino) gravidade = map(inputGravidade, 0, 1023, 0.3, 1.8);
    else gravidade = map(mouseX, 0, width, 0.3, 1.8);
    
    desenharTrajetoria(); 
    if (pulosRestantes <= 0) estadoJogo = "GAMEOVER";
    
    if (inputPulo && !puloAnterior && pulosRestantes > 0) {
       velocidadeY = forcaPulo;
       estadoJogo = "PULANDO";
       pulosRestantes--;
       somMotor.freq(400); 
    }
  }

  // Atualiza física se estiver Pulando, Correndo, Caindo no Buraco OU Batendo no Teto
  if (estadoJogo.equals("PULANDO") || estadoJogo.equals("CORRENDO_VITORIA") || estadoJogo.equals("CAINDO_BURACO") || estadoJogo.equals("BATENDO_TETO")) {
    atualizarFisica();
  }
  
  puloAnterior = inputPulo;
  
  desenharCenario(); 
  desenharPersonagem(); 
  desenharInterface();
}

void atualizarLedsArduino() {
  char comando = 'N'; 
  // Vermelho para qualquer tipo de falha ou queda
  if (estadoJogo.equals("FALHA") || estadoJogo.equals("CAINDO_BURACO") || estadoJogo.equals("BATENDO_TETO")) comando = 'F'; 
  else if (estadoJogo.equals("GAMEOVER")) comando = 'S'; 
  else if (estadoJogo.equals("CORRENDO_VITORIA")) comando = 'V'; 
  
  if (comando != ultimoComandoLed) {
    minhaPorta.write(comando);
    ultimoComandoLed = comando;
  }
}

void lerInputs() {
  if (!usarArduino) {
    inputGravidade = mouseX; 
    inputPulo = keyPressed && key == ' '; 
  }
}

void serialEvent(Serial p) {
  try {
    String msg = trim(p.readStringUntil('\n'));
    if (msg != null) {
      String[] vals = split(msg, ';');
      if (vals.length == 2) {
        inputPulo = (int(vals[0]) == 1); inputGravidade = float(vals[1]);
      }
    }
  } catch(Exception e) {}
}

void atualizarFisica() {
  // Só move para frente se não estiver caindo (seja buraco ou teto)
  if (!estadoJogo.equals("CAINDO_BURACO") && !estadoJogo.equals("BATENDO_TETO")) {
     playerX += velocidadeX;
  }
  
  playerY += velocidadeY;
  velocidadeY += gravidade;
  
  // --- 1. Colisão Teto (NOVA LÓGICA) ---
  if ((playerY - charHeight) < tetoY) { 
    playerY = tetoY + charHeight; 
    // Se bateu no teto, inicia a queda "invertida"
    if (!estadoJogo.equals("BATENDO_TETO")) {
       estadoJogo = "BATENDO_TETO";
       tocarSomFalha(); // Toca o som do impacto
    }
  }
  
  // --- 2. Colisão Chão/Buraco ---
  // O personagem só interage com o chão se NÃO estiver na animação de bater no teto
  if (playerY >= chaoY && !estadoJogo.equals("BATENDO_TETO")) {
    
    boolean sobreBuraco = false;
    for (PVector b : buracos) {
      if (playerX > (b.x + 10) && playerX < (b.x + b.y - 10)) { 
        sobreBuraco = true; 
        break; 
      }
    }
    
    if (sobreBuraco) {
      estadoJogo = "CAINDO_BURACO";
    } else {
      if (!estadoJogo.equals("CAINDO_BURACO")) {
        playerY = chaoY; velocidadeY = 0;
        if (playerX > fimDoPerigo) {
          if (!estadoJogo.equals("CORRENDO_VITORIA")) tocarSomVitoria();
          estadoJogo = "CORRENDO_VITORIA";
        }
        else if (estadoJogo.equals("PULANDO")) estadoJogo = "CALIBRANDO";
        if (playerX > width) proximaFase();
      }
    }
  }
  
  // 3. Verifica se caiu para fora da tela (Morte Real final)
  if (playerY > height + 50) {
    // Se caiu por buraco ou por teto, agora finaliza o estado
    if (estadoJogo.equals("CAINDO_BURACO") || estadoJogo.equals("BATENDO_TETO")) {
       estadoJogo = "FALHA";
    }
  }
}

// Função auxiliar para tocar o som de erro sem mudar o estado imediatamente
void tocarSomFalha() {
  somFalha.play();
  envelope.play(somFalha, 0.01, 0.05, 0.05, 0.2); 
}

// Função antiga mantida para compatibilidade se needed
void registrarFalha() {
  estadoJogo = "FALHA";
  tocarSomFalha();
}

void tocarSomVitoria() {
  somVitoria.play();
  somVitoria.freq(523.25); 
  envelope.play(somVitoria, 0.01, 0.2, 0.1, 1.0); 
}

// --- TRAJETÓRIA PONTILHADA ---
void desenharTrajetoria() {
  fill(255); 
  noStroke();
  
  float sx = playerX;
  float sy = playerY;
  float sv = forcaPulo;
  
  if (pulosRestantes > 0) {
    for (int i = 0; i < 90; i++) {
      if (i % 4 == 0) ellipse(sx, sy, 5, 5);
      sx += velocidadeX;
      sy += sv;
      sv += gravidade;
      if (sy > chaoY) break;
    }
  }
}

void desenharCenario() {
  noStroke();
  // Teto um pouco mais visível para indicar perigo
  fill(255, 0, 0,100); 
  rectMode(CORNER);
  rect(0, 0, width, 20);
  
  if (imagensCarregadas && imgChao != null) {
    for (int x = 0; x < width; x += tamanhoBloco) {
      boolean eBuraco = false;
      float centroBloco = x + (tamanhoBloco/2);
      
      for (PVector b : buracos) {
        if (centroBloco > b.x && centroBloco < b.x + b.y) {
          eBuraco = true;
          break;
        }
      }
      
      if (!eBuraco) {
        imageMode(CORNER);
        image(imgChao, x, chaoY);
        for (int y = (int)chaoY + tamanhoBloco; y < height; y += tamanhoBloco) {
           tint(150); image(imgChao, x, y); noTint(); 
        }
      }
    }
    
    if (imgFlag != null && fimDoPerigo > 0) {
      imageMode(CENTER);
      image(imgFlag, fimDoPerigo + 30, chaoY - 30); 
    }
    
  } else {
    fill(100); rectMode(CORNER);
    rect(0, chaoY, width, height - chaoY);
    fill(0); for (PVector b : buracos) rect(b.x, chaoY, b.y, height - chaoY); 
  }
  imageMode(CENTER); 
}

void desenharPersonagem() {
  pushMatrix();
  translate(playerX, playerY - (charHeight / 2) + ajusteY);

  if (!imagensCarregadas) {
    fill(0, 150, 255); rectMode(CENTER); rect(0, 0, charWidth, charHeight); 
  } 
  // --- NOVA LÓGICA DE DESENHO AO BATER NO TETO ---
  else if (estadoJogo.equals("BATENDO_TETO")) {
    rotate(HALF_PI);
    image(animJump[7], 0, 0); 
  }
  else if (estadoJogo.equals("CAINDO_BURACO")) {
    image(animJump[7], 0, 0);
  }
  else if (estadoJogo.equals("PULANDO") || estadoJogo.equals("CORRENDO_VITORIA")) {
    int framePulo = int(map(velocidadeY, forcaPulo, 15, 0, 7));
    framePulo = constrain(framePulo, 0, 7);
    image(animJump[framePulo], 0, 0);
  } 
  else {
    image(imgIdle, 0, 0);
  }
  popMatrix();
}

void desenharInterface() {
  // --- 1. PAINEL DE INFORMAÇÕES (HUD) ---
  noStroke();
  
  // Caixa de Fundo (Preto com transparência 180 de 255)
  // rect(x, y, largura, altura, arredondamento)
  fill(0, 0, 0, 180); 
  rectMode(CORNER);
  rect(10, 20, 230, 100, 15); // Cantos arredondados (15px)
  
  // Texto e Elementos
  fill(255); 
  textSize(20); 
  textAlign(LEFT);
  
  // Fase
  text("Fase: " + fase, 30, 45); // Ajustei margem para dentro da caixa
  
  // Barra de Gravidade
  float hBarra = map(gravidade, 0.3, 1.8, 5, 100);
  // Cor dinâmica da barra
  fill(map(gravidade, 0.3, 1.8, 0, 255), 100, 255 - map(gravidade, 0.3, 1.8, 0, 255)); 
  rect(30, 60, hBarra, 12, 5); // Barra com cantos levemente arredondados
  
  fill(255); 
  textSize(14); // Texto um pouco menor para caber bonito
  text("Gravidade", 40 + hBarra, 71); // Texto ao lado da barra

  // Contador de Pulos
  textSize(20);
  text("Pulos:", 30, 105);
  for(int i=0; i<maxPulos; i++) {
    if(i < pulosRestantes) fill(0, 200, 255); // Azul neon
    else fill(80); // Cinza apagado
    // Bolinhas ou Quadrados para os pulos
    rect(100 + (i*25), 90, 15, 15, 4); // Quadrados arredondados
  }
  
  // --- 2. PAINEL DE MENSAGENS CENTRAIS (Pop-ups) ---
  // Só desenha se tiver alguma mensagem importante
  if (estadoJogo.equals("FALHA") || estadoJogo.equals("GAMEOVER") || estadoJogo.equals("CORRENDO_VITORIA")) {
    
    rectMode(CENTER);
    
    // Sombra/Caixa de Fundo da Mensagem
    fill(0, 0, 0, 200); // Mais escuro para destacar
    rect(width/2, height/2, 300, 100, 20); // Caixa centralizada
    
    textAlign(CENTER);
    
    if (estadoJogo.equals("FALHA")) { 
      fill(255, 80, 80); // Vermelho Claro
      textSize(30);
      text("VOCÊ FALHOU!", width/2, height/2 - 10);
      textSize(16); fill(200);
      text("Pressione 'R' para tentar de novo", width/2, height/2 + 25);
    } 
    else if (estadoJogo.equals("GAMEOVER")) { 
      fill(255, 150, 0); // Laranja
      textSize(30);
      text("SEM ENERGIA!", width/2, height/2 - 10);
      textSize(16); fill(200);
      text("Seus pulos acabaram. 'R' para reiniciar.", width/2, height/2 + 25);
    }
    else if (estadoJogo.equals("CORRENDO_VITORIA")) { 
      fill(100, 255, 100); // Verde Claro
      textSize(35);
      text("SUCESSO!", width/2, height/2 + 10);
    }
    
    rectMode(CORNER); // Volta ao padrão para não bugar o resto
  }
}

void iniciarNovaFase() {
  playerX = 50; playerY = chaoY; velocidadeY = 0; estadoJogo = "CALIBRANDO"; pulosRestantes = maxPulos; gerarBuracos();
}

// --- GERADOR DE BURACOS (VOLTOU PARA MÁXIMO 2) ---
void gerarBuracos() {
  buracos.clear(); 
  fimDoPerigo = 0;
  
  boolean doisBuracos = (fase >= 2); 
  
  // Buraco 1
  float b1X = random(200, 350); 
  float b1W = random(80, 120);
  buracos.add(new PVector(b1X, b1W)); 
  fimDoPerigo = b1X + b1W;
  
  // Buraco 2 (se fase >= 2)
  if (doisBuracos) {
    float b2X = b1X + b1W + random(120, 200); // Garante chão entre eles
    float b2W = random(80, 120);
    // Verifica se cabe na tela
    if (b2X + b2W < width - 20) { 
      buracos.add(new PVector(b2X, b2W)); 
      fimDoPerigo = b2X + b2W; 
    }
  }
}

void proximaFase() { fase++; iniciarNovaFase(); }

void keyPressed() {
  if (key == 'r' || key == 'R') {
    if (estadoJogo.equals("FALHA") || estadoJogo.equals("GAMEOVER")) iniciarNovaFase();
  }
}
