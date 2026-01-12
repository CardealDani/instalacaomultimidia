import processing.serial.*;
import processing.sound.*;

// --- CONFIGURAÇÃO ---
boolean usarArduino = false; 
Serial minhaPorta;

// --- SISTEMA DE SOM ---
SinOsc somMotor;        // Zumbido da gravidade (Senoidal)
TriOsc somVitoria;      // Som de passar de fase (Triangular = mais suave/musical)
WhiteNoise somFalha;    // Som de erro (Chiado)
Env envelope;           // Controlador de volume (Fade in/out)

// --- VARIÁVEIS DO JOGO ---
int fase = 1;
int maxPulos = 3; 
int pulosRestantes;
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

void setup() {
  size(800, 400);
  
  // --- INICIALIZAÇÃO DE SOM ---
  somMotor = new SinOsc(this);
  somMotor.play();
  somMotor.amp(0.0); // Começa mudo
  
  somVitoria = new TriOsc(this); // Triangular é bom para sons de "moeda" ou "sucesso"
  somFalha = new WhiteNoise(this);
  envelope = new Env(this); // Envelope para controlar a duração dos efeitos
  
  // Tenta conectar Arduino
  if (usarArduino) {
    try {
      minhaPorta = new Serial(this, Serial.list()[0], 9600);
      minhaPorta.bufferUntil('\n'); 
    } catch (Exception e) {
      println("Arduino offline. Usando Mouse.");
      usarArduino = false;
    }
  }
  
  iniciarNovaFase();
}

void draw() {
  background(30); 
  lerInputs();

  // --- GERENCIAMENTO DE ÁUDIO ---
  // Mapeia gravidade para frequências mais GRAVES e CONFORTÁVEIS (60Hz a 300Hz)
  // Antes era até 800Hz (muito agudo)
  float frequencia = map(gravidade, 0.3, 1.8, 300, 60);
  somMotor.freq(frequencia);
  
  // Volume Dinâmico (Muito mais baixo e sutil)
  if (estadoJogo.equals("CALIBRANDO")) {
    somMotor.amp(0.05); // Volume 5% (Bem baixinho, só um feedback tátil sonoro)
  } else {
    somMotor.amp(0.0);  // Mudo se ganhou ou perdeu
  }

  // --- LÓGICA DO JOGO ---
  if (estadoJogo.equals("CALIBRANDO")) {
    if (usarArduino) gravidade = map(inputGravidade, 0, 1023, 0.3, 1.8);
    else gravidade = map(mouseX, 0, width, 0.3, 1.8);
    
    desenharTrajetoria();
    if (pulosRestantes <= 0) estadoJogo = "GAMEOVER";
    
    // PULO
    if (inputPulo && !puloAnterior && pulosRestantes > 0) {
       velocidadeY = forcaPulo;
       estadoJogo = "PULANDO";
       pulosRestantes--;
       // Pequeno "chirp" no motor ao pular
       somMotor.freq(400); 
    }
  }

  if (estadoJogo.equals("PULANDO") || estadoJogo.equals("CORRENDO_VITORIA")) {
    atualizarFisica();
  }
  
  puloAnterior = inputPulo;
  
  desenharCenario();
  desenharPersonagem();
  desenharInterface();
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
        inputPulo = (int(vals[0]) == 1); 
        inputGravidade = float(vals[1]);
      }
    }
  } catch(Exception e) {}
}

void atualizarFisica() {
  playerX += velocidadeX;
  if (estadoJogo.equals("PULANDO")) {
    playerY += velocidadeY;
    velocidadeY += gravidade;
  }
  
  // Colisões
  if ((playerY - 15) < tetoY) { playerY = tetoY; registrarFalha(); }
  
  if (playerY >= chaoY) {
    boolean caiu = false;
    for (PVector b : buracos) {
      if (playerX > b.x && playerX < b.x + b.y) { caiu = true; break; }
    }
    
    if (caiu) { registrarFalha(); } 
    else {
      playerY = chaoY; velocidadeY = 0;
      if (playerX > fimDoPerigo) {
        // Só toca o som de vitória UMA VEZ quando entra no estado de vitória
        if (!estadoJogo.equals("CORRENDO_VITORIA")) {
           tocarSomVitoria();
        }
        estadoJogo = "CORRENDO_VITORIA";
      }
      else if (estadoJogo.equals("PULANDO")) estadoJogo = "CALIBRANDO";
      
      if (playerX > width) proximaFase();
    }
  }
}

void registrarFalha() {
  estadoJogo = "FALHA";
  // Efeito de chiado curto (Impacto)
  somFalha.play();
  envelope.play(somFalha, 0.01, 0.05, 0.05, 0.2); 
}

void tocarSomVitoria() {
  // Configura um som musical (Triângulo)
  somVitoria.play();
  somVitoria.freq(523.25); // Nota Dó (C5)
  // Envelope: Ataque rápido, delay médio (som de sino/chime)
  envelope.play(somVitoria, 0.01, 0.2, 0.08, 1.0); 
}

void desenharTrajetoria() {
  stroke(255, 255, 0, 100); strokeWeight(3); noFill();
  beginShape();
  float sx = playerX, sy = playerY, sv = forcaPulo;
  if (pulosRestantes > 0) {
    for (int i = 0; i < 90; i++) {
      vertex(sx, sy); sx += velocidadeX; sy += sv; sv += gravidade;
      if (sy > chaoY) break;
    }
  }
  endShape(); noStroke();
}

void desenharCenario() {
  fill(255, 50, 50, 50); rect(0, 0, width, 20);
  fill(100); rect(0, chaoY + 20, width, height - chaoY); 
  fill(50, 0, 0); 
  for (PVector b : buracos) rect(b.x, chaoY + 20, b.y, height - chaoY);
}

void desenharPersonagem() {
  pushMatrix(); translate(playerX + 15, playerY + 15);
  if (estadoJogo.equals("PULANDO") || estadoJogo.equals("CORRENDO_VITORIA")) rotate(frameCount * 0.15);
  fill(0, 150, 255); rectMode(CENTER); rect(0, 0, 30, 30); rectMode(CORNER); popMatrix();
}

void desenharInterface() {
  fill(255); textSize(20); textAlign(LEFT);
  text("Fase: " + fase, 20, 50);
  
  // Visualizador de Audio (Mais discreto)
  float hBarra = map(gravidade, 0.3, 1.8, 5, 50);
  fill(0, 255, 150); noStroke();
  rect(20, 70, hBarra, 10);
  text("Motor G", 25 + hBarra, 80);

  text("Pulos:", 20, 110);
  for(int i=0; i<maxPulos; i++) {
    if(i < pulosRestantes) fill(0, 200, 255); else fill(80); 
    rect(100 + (i*25), 95, 15, 15);
  }
  
  textAlign(CENTER);
  if (estadoJogo.equals("FALHA")) { fill(255, 50, 50); text("FALHOU! (R)", width/2, height/2); } 
  else if (estadoJogo.equals("GAMEOVER")) { fill(255, 100, 0); text("SEM ENERGIA! (R)", width/2, height/2); }
  else if (estadoJogo.equals("CORRENDO_VITORIA")) { fill(0, 255, 0); text("SUCESSO!", width/2, height/2 - 40); }
}

void iniciarNovaFase() {
  playerX = 50; playerY = chaoY; velocidadeY = 0; estadoJogo = "CALIBRANDO"; pulosRestantes = maxPulos; gerarBuracos();
}

void gerarBuracos() {
  buracos.clear(); fimDoPerigo = 0;
  boolean doisBuracos = (fase >= 2); 
  float b1X = random(200, 350); float b1W = random(80, 120);
  buracos.add(new PVector(b1X, b1W)); fimDoPerigo = b1X + b1W;
  if (doisBuracos) {
    float b2X = b1X + b1W + random(120, 200); float b2W = random(80, 120);
    if (b2X + b2W < width - 20) { buracos.add(new PVector(b2X, b2W)); fimDoPerigo = b2X + b2W; }
  }
}

void proximaFase() { fase++; iniciarNovaFase(); }

void keyPressed() {
  if (key == 'r' || key == 'R') {
    if (estadoJogo.equals("FALHA") || estadoJogo.equals("GAMEOVER")) iniciarNovaFase();
  }
}
