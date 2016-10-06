
/****************************************************
 *                                                  *
 * Programa para medicao de velocidade de motor     *
 * atraves de encoder de quadratura.                *
 * (c) Ronan Paixao <ronan@dapaixao.com.br>         *
 *     William Schlickmann <wschlickmann@gmail.com> *
 * Julho 2011                                       *
 *                                                  *
 ***************************************************/

// Modos disponiveis
#define MODE_STEP_TIME  1  /* Este modo conta o nr de passos por tempo (1s) */
#define MODE_TIME_STEP  2  /* Este modo conta o tempo (ms) a cada passo */

//-------8<------- Inicio da configuracao -------8<-------

// Pinos de saida dos PWM no Arduino
#define pwm1pin  9
#define pwm2pin  10

// Registradores de controle
#define pwm1control OCR1A
#define pwm2control OCR1B

// Valores iniciais
#define pwm1null 0
#define pwm2null 0

// Registrador de valor maximo
#define pwm1top  ICR1
#define pwm2top  ICR1

// Quantos pontos o intervalo de varredura (top) eh dividido
#define sweep_points 120

// Quantos passos do encoder por cada volta da roda
#define step_turn    390

// Pinos de leitura das saidas do encoder
// encoder1pin deve ser 2 ou 3
#define encoder1pin  2
#define encoder2pin  3

// Configuracao do modo
#define MODE  MODE_TIME_STEP


//-------8<------- Fim da configuracao -------8<-------

// Variaveis (volatile porque sao modificadas em interrupcao)
volatile long int passo = 0;
volatile long int last_step_time, this_step_time, step_time;
volatile float rad_s;

void setup()
{
  // Setup do PWM
  pinMode(pwm1pin, OUTPUT);
  pinMode(pwm2pin, OUTPUT);
  TCCR1B = 0b00011001;       // Fast PWM, top in ICR1, /1 prescale (62.5ns)
  TCCR1A = 0b10100010;       //clear on compare match, fast PWM
  pwm1top =  16000-1;        // frequencia do PWM=1kHz  <-  16000 clocks @ 62.5ns = 1ms
  pwm1control = pwm1null;    // valor inicial pwm1
  pwm2control = pwm2null;    // valor inicial pwm2
  
  Serial.begin(115200);      // Inicio da comunicacao serial
  
  // Setup do encoder
  pinMode(encoder1pin, INPUT);
  pinMode(encoder2pin, INPUT);
  // Colocando entradas em pull-up
  digitalWrite(encoder1pin, HIGH);
  digitalWrite(encoder2pin, HIGH);
  // Interrupcao quando o pino encoder1 sobe
  // o pino do encoder 1 deve ter suporte a interrupcao externa, ou seja,
  // suporte a funcao attachInterrupt (pinos 2 ou 3 no Arduino Uno)
  #if (encoder1pin==2)
    attachInterrupt(0, decoder, RISING);
  #elif (encoder1pin==3)
    attachInterrupt(1, decoder, RISING);
  #else
    #error "O encoder1pin deve ser 2 ou 3"
  #endif
  
  last_step_time = micros();
}


void loop()
{
  long int count_start, count_end;
  
  // Varredura da saida do PWM
  for (int i=0;i<sweep_points;i++) {
    pwm1control = pwm1top/sweep_points*i;
    
    #if (MODE==MODE_STEP_TIME)
      count_start = passo;
      delay(1000);   // 1 segundo
      count_end = passo;
      // velocidade da roda em rad/s
      rad_s = (2*M_PI/step_turn*(count_end-count_start));
    #endif
    
    // Impressao dos dados obtidos na porta serial.
    // Formato:
    // tempo[ms]    posicao do encoder[passos]    velocidade[rad/s]
    // As colunas são separadas pelo caractere de tabulação para facilitar a operação de
    // copiar/colar em tabelas e planilhas
    Serial.print(millis());
    Serial.print("\t");
    Serial.print(passo);
    Serial.print("\t");
    Serial.println(rad_s);
  }
}

// Funcao executada quando o pino do encoder1 sobe
void decoder()
{
  last_step_time = this_step_time;
  this_step_time = micros();
  #if (MODE==MODE_TIME_STEP)
    // velocidade da roda em rad/s
    rad_s = 2*M_PI*1e6/step_turn/(this_step_time-last_step_time);
  #endif
  
  // Neste caso, digitalRead(encoder1pin) sempre sera HIGH
  if (digitalRead(encoder2pin) == digitalRead(encoder1pin))
  {
    passo++; // Se os valores do encoder forem iguais, a direcao eh horaria
  }
  else
  {
    passo--; // Se os valores do encoder forem diferentes, a direcao eh anti-horaria
  }
}



